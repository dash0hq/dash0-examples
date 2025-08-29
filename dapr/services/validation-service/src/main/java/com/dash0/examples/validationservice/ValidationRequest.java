package com.dash0.examples.validationservice;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;

/**
 * Request model for validation endpoint
 */
public class ValidationRequest {
    
    @NotNull(message = "Name is required")
    @JsonProperty("name")
    private String name;
    
    public ValidationRequest() {}
    
    public ValidationRequest(String name) {
        this.name = name;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    @Override
    public String toString() {
        return "ValidationRequest{" +
                "name='" + name + '\'' +
                '}';
    }
}