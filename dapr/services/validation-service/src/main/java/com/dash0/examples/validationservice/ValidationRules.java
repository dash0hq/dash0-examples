package com.dash0.examples.validationservice;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Model representing validation rules configuration
 */
public class ValidationRules {
    
    @JsonProperty("minLength")
    private int minLength;
    
    @JsonProperty("maxLength")
    private int maxLength;
    
    @JsonProperty("forbiddenWords")
    private List<String> forbiddenWords;
    
    @JsonProperty("profanityCheck")
    private boolean profanityCheck;
    
    @JsonProperty("externalApiCheck")
    private boolean externalApiCheck;
    
    public ValidationRules() {}
    
    public ValidationRules(int minLength, int maxLength, List<String> forbiddenWords, 
                          boolean profanityCheck, boolean externalApiCheck) {
        this.minLength = minLength;
        this.maxLength = maxLength;
        this.forbiddenWords = forbiddenWords;
        this.profanityCheck = profanityCheck;
        this.externalApiCheck = externalApiCheck;
    }
    
    public int getMinLength() {
        return minLength;
    }
    
    public void setMinLength(int minLength) {
        this.minLength = minLength;
    }
    
    public int getMaxLength() {
        return maxLength;
    }
    
    public void setMaxLength(int maxLength) {
        this.maxLength = maxLength;
    }
    
    public List<String> getForbiddenWords() {
        return forbiddenWords;
    }
    
    public void setForbiddenWords(List<String> forbiddenWords) {
        this.forbiddenWords = forbiddenWords;
    }
    
    public boolean isProfanityCheck() {
        return profanityCheck;
    }
    
    public void setProfanityCheck(boolean profanityCheck) {
        this.profanityCheck = profanityCheck;
    }
    
    public boolean isExternalApiCheck() {
        return externalApiCheck;
    }
    
    public void setExternalApiCheck(boolean externalApiCheck) {
        this.externalApiCheck = externalApiCheck;
    }
    
    @Override
    public String toString() {
        return "ValidationRules{" +
                "minLength=" + minLength +
                ", maxLength=" + maxLength +
                ", forbiddenWords=" + forbiddenWords +
                ", profanityCheck=" + profanityCheck +
                ", externalApiCheck=" + externalApiCheck +
                '}';
    }
}