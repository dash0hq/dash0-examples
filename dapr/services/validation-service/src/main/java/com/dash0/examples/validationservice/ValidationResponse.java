package com.dash0.examples.validationservice;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Response model for validation endpoint
 */
public class ValidationResponse {
    
    @JsonProperty("valid")
    private boolean valid;
    
    @JsonProperty("message")
    private String message;
    
    public ValidationResponse() {}
    
    public ValidationResponse(boolean valid, String message) {
        this.valid = valid;
        this.message = message;
    }
    
    public boolean isValid() {
        return valid;
    }
    
    public void setValid(boolean valid) {
        this.valid = valid;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    @Override
    public String toString() {
        return "ValidationResponse{" +
                "valid=" + valid +
                ", message='" + message + '\'' +
                '}';
    }
}