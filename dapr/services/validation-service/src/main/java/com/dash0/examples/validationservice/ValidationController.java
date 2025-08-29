package com.dash0.examples.validationservice;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * REST Controller for validation service endpoints
 */
@RestController
@RequestMapping("/")
public class ValidationController {
    
    private static final Logger logger = LoggerFactory.getLogger(ValidationController.class);
    
    @Autowired
    private ValidationService validationService;
    
    /**
     * Validate a todo name
     */
    @PostMapping("/validate")
    public ResponseEntity<ValidationResponse> validateTodo(
            @Valid @RequestBody ValidationRequest request,
            HttpServletRequest httpRequest) {
        
        try {
            logger.info("Received validation request for: {}", request.getName());
            
            logTraceHeaders(httpRequest);
            
            ValidationResponse response = validationService.validateTodoName(request.getName());
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error validating todo", e);
            ValidationResponse errorResponse = new ValidationResponse(false, "Validation service error");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    /**
     * Get current validation rules
     */
    @GetMapping("/rules")
    public ResponseEntity<ValidationRules> getRules() {
        try {
            ValidationRules rules = validationService.getCurrentRules();
            return ResponseEntity.ok(rules);
        } catch (Exception e) {
            logger.error("Error fetching rules", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    
    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> health = Map.of(
            "status", "UP",
            "service", "validation-service",
            "timestamp", LocalDateTime.now().toString()
        );
        return ResponseEntity.ok(health);
    }
    
    /**
     * Handle validation errors
     */
    @ExceptionHandler(org.springframework.web.bind.MethodArgumentNotValidException.class)
    public ResponseEntity<ValidationResponse> handleValidationException(
            org.springframework.web.bind.MethodArgumentNotValidException ex) {
        
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getDefaultMessage())
                .findFirst()
                .orElse("Validation failed");
                
        ValidationResponse response = new ValidationResponse(false, message);
        return ResponseEntity.badRequest().body(response);
    }
    
    /**
     * Handle general exceptions
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ValidationResponse> handleGeneralException(Exception ex) {
        logger.error("Unexpected error", ex);
        ValidationResponse response = new ValidationResponse(false, "Internal server error");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
    
    /**
     * Log trace headers for debugging
     */
    private void logTraceHeaders(HttpServletRequest request) {
        logger.info("Incoming headers:");
        request.getHeaderNames().asIterator().forEachRemaining(headerName -> {
            if (headerName.toLowerCase().contains("trace") || 
                headerName.toLowerCase().contains("span") ||
                headerName.toLowerCase().contains("x-")) {
                logger.info("{}: {}", headerName, request.getHeader(headerName));
            }
        });
        
        String traceparent = request.getHeader("traceparent");
        if (traceparent != null) {
            logger.info("Found traceparent header: {}", traceparent);
        }
        
        String traceId = request.getHeader("x-trace-id");
        if (traceId != null) {
            logger.info("Found x-trace-id header: {}", traceId);
        }
    }
}