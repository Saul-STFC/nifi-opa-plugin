package org.nifiopa.nifiopa;

import java.time.Duration;
import java.util.Map;

import org.apache.nifi.authorization.AuthorizationRequest;
import org.apache.nifi.authorization.AuthorizationResult;
import org.apache.nifi.authorization.Authorizer;
import org.apache.nifi.authorization.AuthorizerConfigurationContext;
import org.apache.nifi.authorization.AuthorizerInitializationContext;
import org.apache.nifi.authorization.exception.AuthorizationAccessException;
import org.apache.nifi.authorization.exception.AuthorizerCreationException;
import org.apache.nifi.authorization.exception.AuthorizerDestructionException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.styra.opa.OPAClient;
import com.styra.opa.OPAException;

public class OpaAuthorizer implements Authorizer {

    private static final Logger logger =
            LoggerFactory.getLogger(OpaAuthorizer.class);

    private static final String OPA_URI_PROPNAME = "OPA_URI";
    private static final String OPA_RULE_HEAD_PROPNAME = "OPA_RULE_HEAD";
    private static final String HTTP_POOL_SIZE_PROPNAME = "OPA_HTTP_POOL_SIZE";
    private static final String HTTP_POOL_SIZE_DEFAULT = "32";
    private static final String HTTP_CONNECT_TIMEOUT_MS_PROPNAME = "OPA_HTTP_CONNECT_TIMEOUT_MS";
    private static final String HTTP_CONNECT_TIMEOUT_MS_DEFAULT = "2000";
    private static final String HTTP_REQUEST_TIMEOUT_MS_PROPNAME = "OPA_HTTP_REQUEST_TIMEOUT_MS";
    private static final String HTTP_REQUEST_TIMEOUT_MS_DEFAULT = "5000";

    private volatile OPAClient opaClient;
    private volatile RequestCache cache;
    private volatile PooledHttpClient pooledHttpClient;
    private volatile String opaRuleHead;

    @Override
    public AuthorizationResult authorize(AuthorizationRequest request)
            throws AuthorizationAccessException {
        // Copy the currently published components into local variables. This avoids
        // repeatedly reading volatile fields while processing the authorization
        // request.
        OPAClient currentClient = this.opaClient;
        RequestCache currentCache = this.cache;
        String currentRuleHead = this.opaRuleHead;

        if (currentClient == null || currentCache == null || currentRuleHead == null) {
            logger.error("OPA authorizer is not configured or is shutting down.");
            return AuthorizationResult.denied("OPA authorizer is not available.");
        }

        AuthorizationResult cachedResult = currentCache.getCachedResult(request);
        if (cachedResult != null) {
            logger.debug("PolicyCache: Cache hit.");
            return cachedResult;
        }

        final Map<String, Map<String, String>> requestForm;
        try {
            /* CREATING REQUEST */
            requestForm = Map.of(
                    "action",
                    Map.of("name", request.getAction().toString()),

                    "identity",
                    Map.of("name", request.getIdentity() != null ? request.getIdentity() : "",
                            "groups", request.getGroups() != null ? String.join(",", request.getGroups()) : ""),

                    "resource",
                    Map.of("name", request.getResource().getName(),
                            "id", request.getResource().getIdentifier(),
                            "safeDescription", request.getResource().getSafeDescription()),

                    "requestedResource",
                    Map.of("name", request.getRequestedResource().getName(),
                            "id", request.getRequestedResource().getIdentifier(),
                            "safeDescription", request.getRequestedResource().getSafeDescription()),

                    "properties",
                    Map.of("isAccessAttempt", Boolean.toString(request.isAccessAttempt()),
                            "isAnonymous", Boolean.toString(request.isAnonymous())),

                    "userContext",
                    request.getUserContext() != null ? request.getUserContext() : Map.of(),

                    "resourceContext",
                    request.getResourceContext() != null ? request.getResourceContext() : Map.of());

        } catch (RuntimeException e) {
            logger.error("An error occurred while building the OPA request.", e);
            return AuthorizationResult.denied("An error occurred while building the OPA request.");
        }

        final OPAResponse opaResponse;
        try {
            opaResponse = currentClient.evaluate(currentRuleHead, requestForm, OPAResponse.class);
        } catch (OPAException | RuntimeException e) {
            logger.error("An error occurred while querying OPA.", e);
            return AuthorizationResult.denied("An error occurred while querying OPA.");
        }

        if (opaResponse == null) {
            logger.error("An error occurred while unmarshalling the OPA response.");
            return AuthorizationResult.denied("An error occurred while reading the OPA response.");
        }
        // Cache invalidation belongs to this response only. 
        // Do not store dumpCache as a shared state
        if (opaResponse.dumpCache()) {
            currentCache.clear();
            logger.debug("PolicyCache: Cache cleared.");
        }

        // Build a single result object
        final AuthorizationResult result;
        if (opaResponse.resourceNotFound()) {
            result = AuthorizationResult.resourceNotFound();
            logger.debug("Authorizer-Result: Resource not found");
        } else if (opaResponse.allowed()) {
            result = AuthorizationResult.approved();
            logger.debug("Authorizer-Result: Access was approved");
        } else {
            String message = opaResponse.message();
            result = AuthorizationResult.denied(
                    message != null && !message.trim().isEmpty() ? message : "Access denied.");
            logger.debug("Authorizer-Result: Access was denied");
        }

        currentCache.putCachedResult(request, result);
        return result;
    }

    @Override
    public void initialize(AuthorizerInitializationContext initializationContext)
            throws AuthorizerCreationException {
    }

    @Override
    public synchronized void onConfigured(AuthorizerConfigurationContext configurationContext)
            throws AuthorizerCreationException {

        String uri = ConfigLoader.getProperty(configurationContext, OPA_URI_PROPNAME);
        String ruleHead = ConfigLoader.getProperty(configurationContext, OPA_RULE_HEAD_PROPNAME);

        int poolSize = parsePositiveIntProp(configurationContext, HTTP_POOL_SIZE_PROPNAME, HTTP_POOL_SIZE_DEFAULT);
        int connectTimeoutMs = parsePositiveIntProp(configurationContext, HTTP_CONNECT_TIMEOUT_MS_PROPNAME, HTTP_CONNECT_TIMEOUT_MS_DEFAULT);
        int requestTimeoutMs = parsePositiveIntProp(configurationContext, HTTP_REQUEST_TIMEOUT_MS_PROPNAME, HTTP_REQUEST_TIMEOUT_MS_DEFAULT);

        PooledHttpClient newHttpClient = null;
        try {
            // Build one shared HTTP transport for all OPA authorization requests.
            newHttpClient = new PooledHttpClient(
                    poolSize,
                    Duration.ofMillis(connectTimeoutMs),
                    Duration.ofMillis(requestTimeoutMs));

            OPAClient newOpaClient = new OPAClient(uri, newHttpClient);

            RequestCache newCache = new RequestCache();
            newCache.initialize(configurationContext);

            PooledHttpClient oldHttpClient = this.pooledHttpClient;

            this.opaRuleHead = ruleHead;
            this.opaClient = newOpaClient;
            this.pooledHttpClient = newHttpClient;
            this.cache = newCache;

            if (oldHttpClient != null) {
                oldHttpClient.close();
            }
        } catch (RuntimeException e) {
            if (newHttpClient != null) {
                newHttpClient.close();
            }
            throw e;
        }
    }

    @Override
    public synchronized void preDestruction() throws AuthorizerDestructionException {
        this.cache = null;

        PooledHttpClient client = this.pooledHttpClient;
        this.pooledHttpClient = null;
        this.opaClient = null;
        this.opaRuleHead = null;

        if (client != null) {
            client.close();
        }
    }

    private static int parsePositiveIntProp(
            AuthorizerConfigurationContext ctx, String name, String defaultValue) {
        String raw = ConfigLoader.getProperty(ctx, name, defaultValue);
        final int value;
        try {
            value = Integer.parseInt(raw);
        } catch (NumberFormatException e) {
            throw new AuthorizerCreationException(
                    "Invalid integer value for property " + name + ": " + raw);
        }
        if (value <= 0) {
            throw new AuthorizerCreationException(
                    "Property " + name + " must be greater than zero, but was: " + value);
        }
        return value;
    }
}

