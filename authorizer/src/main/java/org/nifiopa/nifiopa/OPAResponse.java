package org.nifiopa.nifiopa;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class OPAResponse {

    private boolean allowed;
    private boolean resourceNotFound;
    private boolean dumpCache;
    private String message;

    @JsonCreator
    public OPAResponse(
            @JsonProperty("allowed") boolean allowed,
            @JsonProperty("resourceNotFound") boolean resourceNotFound,
            @JsonProperty("dumpCache") boolean dumpCache,
            @JsonProperty("message") String message
    		) {
    	this.allowed = allowed;
        this.resourceNotFound = resourceNotFound;
    	this.dumpCache = dumpCache;
    	this.message = message;
    }

    public boolean allowed() {
        return allowed;
    }

    public boolean resourceNotFound() {
        return resourceNotFound;
    }

    public boolean dumpCache() {
    	return dumpCache;
    }

    public String message() {
    	return message;
    }
}
