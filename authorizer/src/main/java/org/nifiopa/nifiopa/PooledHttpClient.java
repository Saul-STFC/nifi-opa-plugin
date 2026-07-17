package org.nifiopa.nifiopa;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

import com.styra.opa.openapi.utils.HTTPClient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
/**
 * HTTPClient implementation backed by one shared
 * {@link java.net.http.HttpClient}.
 *
 * <p>The Styra SDK's default transport may create a new HttpClient for every
 * OPA request. Under NiFi authorization load, this can create large numbers
 * of executor and selector threads, eventually exhausting the JVM or native
 * operating-system thread limit.</p>
 *
 * <p>This implementation reuses one HttpClient, connection pool, selector
 * infrastructure, and fixed-size executor across all authorization calls.</p>
 *
 * <p>The executor limits the number of worker threads. The queue used by
 * {@link java.util.concurrent.Executors#newFixedThreadPool(int,
 * java.util.concurrent.ThreadFactory)} remains unbounded.</p>
 */
public final class PooledHttpClient implements HTTPClient {

    private static final Logger logger =
            LoggerFactory.getLogger(PooledHttpClient.class);

    private final HttpClient httpClient;
    private final ExecutorService executor;
    private final Duration requestTimeout;

    public PooledHttpClient(
            int poolSize,
            Duration connectTimeout,
            Duration requestTimeout) {

        if (poolSize <= 0) {
            throw new IllegalArgumentException("poolSize must be greater than zero");
        }
        if (connectTimeout == null
                || connectTimeout.isZero()
                || connectTimeout.isNegative()) {
            throw new IllegalArgumentException("connectTimeout must be greater than zero");
        }
        if (requestTimeout == null
                || requestTimeout.isZero()
                || requestTimeout.isNegative()) {
            throw new IllegalArgumentException("requestTimeout must be greater than zero");
        }

        this.requestTimeout = requestTimeout;

        AtomicLong threadId = new AtomicLong();
        ThreadFactory threadFactory = runnable -> {
            Thread thread = new Thread(
                    runnable,
                    "opa-http-pool-" + threadId.incrementAndGet());
            thread.setDaemon(true);
            return thread;
        };
        // Limit the number of HTTP executor worker threads. This prevents the
        // per-request native-thread growth caused by constructing a new HttpClient
        // for every OPA evaluation.
        this.executor = Executors.newFixedThreadPool(poolSize, threadFactory);

        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(connectTimeout)
                .executor(executor)
                .version(HttpClient.Version.HTTP_2)
                .build();

        logger.info(
                "Initialized shared OPA HttpClient "
                        + "(poolSize={}, connectTimeout={}, requestTimeout={})",
                poolSize,
                connectTimeout,
                requestTimeout);
    }

    @Override
    public HttpResponse<InputStream> send(HttpRequest request)
            throws IOException, InterruptedException, URISyntaxException {
        /*
        * Preserve the URI reconstruction behavior used by the upstream OPA HTTP
        * client.
        *
        * The generated SDK can escape path separators such as "/" as "%2F".
        * URI.getPath() returns the decoded path, and constructing a new URI from
        * that value restores literal path separators before sending the request.
        *
        */
        URI oldUri = request.uri();
        URI newUri = new URI(
                oldUri.getScheme(),
                oldUri.getUserInfo(),
                oldUri.getHost(),
                oldUri.getPort(),
                oldUri.getPath(),
                oldUri.getQuery(),
                oldUri.getFragment());

        HttpRequest.Builder builder = HttpRequest.newBuilder(newUri)
                .method(
                        request.method(),
                        request.bodyPublisher().orElse(
                                HttpRequest.BodyPublishers.noBody()))
                .expectContinue(request.expectContinue());

        Map<String, List<String>> headers = request.headers().map();
        for (Map.Entry<String, List<String>> header : headers.entrySet()) {
            for (String value : header.getValue()) {
                builder.header(header.getKey(), value);
            }
        }

        request.version().ifPresent(builder::version);

        if (request.timeout().isPresent()) {
            builder.timeout(request.timeout().get());
        } else {
            builder.timeout(requestTimeout);
        }

        return httpClient.send(
                builder.build(),
                HttpResponse.BodyHandlers.ofInputStream());
    }

    /**
     * Releases the shared HTTP executor when the authorizer is destroyed or
     * reconfigured.
     */
    public void close() {
        executor.shutdown();

        try {
            if (!executor.awaitTermination(5, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
            logger.warn("Interrupted while shutting down OPA HTTP executor", e);
        }
    }
}

