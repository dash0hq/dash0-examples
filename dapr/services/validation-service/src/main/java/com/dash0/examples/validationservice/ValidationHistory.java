package com.dash0.examples.validationservice;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDateTime;

/**
 * Model representing a validation history record
 */
public class ValidationHistory {
    
    @JsonProperty("name")
    private String name;
    
    @JsonProperty("result")
    private boolean result;
    
    @JsonProperty("reason")
    private String reason;
    
    @JsonProperty("timestamp")
    private LocalDateTime timestamp;
    
    @JsonProperty("rules")
    private ValidationRules rules;
    
    public ValidationHistory() {}
    
    public ValidationHistory(String name, boolean result, String reason, 
                           LocalDateTime timestamp, ValidationRules rules) {
        this.name = name;
        this.result = result;
        this.reason = reason;
        this.timestamp = timestamp;
        this.rules = rules;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public boolean isResult() {
        return result;
    }
    
    public void setResult(boolean result) {
        this.result = result;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
    
    public LocalDateTime getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
    
    public ValidationRules getRules() {
        return rules;
    }
    
    public void setRules(ValidationRules rules) {
        this.rules = rules;
    }
    
    @Override
    public String toString() {
        return "ValidationHistory{" +
                "name='" + name + '\'' +
                ", result=" + result +
                ", reason='" + reason + '\'' +
                ", timestamp=" + timestamp +
                ", rules=" + rules +
                '}';
    }
}