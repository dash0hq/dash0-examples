package com.dash0.examples.validationservice;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.util.*;

/**
 * Service class for validation logic and state management
 */
@Service
public class ValidationService {
    
    private static final Logger logger = LoggerFactory.getLogger(ValidationService.class);
    
    private ValidationRules validationRules;
    
    @PostConstruct
    public void initialize() {
        // Initialize validation rules - simple in-memory rules
        validationRules = new ValidationRules(
            3, 
            100, 
            Arrays.asList("spam", "test123", "delete", "bad", "terrible", "awful", "hate", "stupid", "dumb"),
            true,
            false
        );
        
        logger.info("Validation service initialized with {} forbidden words", validationRules.getForbiddenWords().size());
    }
    
    
    
    /**
     * Validate a todo name based on current rules
     */
    public ValidationResponse validateTodoName(String name) {
        if (name == null || name.trim().isEmpty()) {
            return new ValidationResponse(false, "Todo name is required");
        }
        
        try {
            logger.info("Validating todo name: \"{}\"", name);
            
            // Perform validation using in-memory rules
            ValidationResponse result = performValidation(name, validationRules);
            
            logger.info("Validation result: {} - {}", result.isValid(), result.getMessage());
            return result;
            
        } catch (Exception e) {
            logger.error("Validation error", e);
            return new ValidationResponse(false, "Validation service error");
        }
    }
    
    /**
     * Get current validation rules
     */
    public ValidationRules getCurrentRules() {
        return validationRules;
    }
    
    /**
     * Perform the actual validation logic
     */
    private ValidationResponse performValidation(String name, ValidationRules rules) {
        // Check minimum length
        if (name.length() < rules.getMinLength()) {
            return new ValidationResponse(false, 
                String.format("Todo name must be at least %d characters long", rules.getMinLength()));
        }
        
        // Check maximum length
        if (name.length() > rules.getMaxLength()) {
            return new ValidationResponse(false, 
                String.format("Todo name must be less than %d characters long", rules.getMaxLength()));
        }
        
        // Check forbidden words
        String lowerName = name.toLowerCase();
        Optional<String> foundForbiddenWord = rules.getForbiddenWords().stream()
                .filter(word -> lowerName.contains(word.toLowerCase()))
                .findFirst();
                
        if (foundForbiddenWord.isPresent()) {
            return new ValidationResponse(false, 
                String.format("Todo name contains forbidden word: \"%s\"", foundForbiddenWord.get()));
        }
        
        // External API validation is disabled - keeping validation simple
        
        return new ValidationResponse(true, "Todo name is valid");
    }
}