package xyz.kaspernissen.validation;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.metrics.LongCounter;

import java.time.Duration;
import java.util.Map;

@RestController
@RequestMapping("/validate")
public class ValidationController {
    
    private final WebClient webClient;
    private final Tracer tracer;
    private final LongCounter validationCounter;
    
    public ValidationController(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder
            .baseUrl("https://jsonplaceholder.typicode.com")
            .build();
        
        var openTelemetry = GlobalOpenTelemetry.get();
        this.tracer = openTelemetry.getTracer("validation-service");
        this.validationCounter = openTelemetry.getMeter("validation-service")
            .counterBuilder("validations.performed")
            .setDescription("Number of validations performed")
            .build();
    }
    
    @PostMapping("/todo-name")
    public ResponseEntity<ValidationResponse> validateTodoName(@RequestBody ValidationRequest request) {
        Span span = tracer.spanBuilder("validate_todo_name")
            .setAttribute("todo.name", request.getName())
            .setAttribute("service.name", "validation-service")
            .startSpan();
        
        try {
            validationCounter.add(1);
            
            String todoName = request.getName();
            if (todoName == null || todoName.trim().isEmpty()) {
                span.setAttribute("validation.result", "invalid_empty");
                return ResponseEntity.badRequest()
                    .body(new ValidationResponse(false, "Todo name cannot be empty"));
            }
            
            // Check for profanity/bad words
            boolean containsBadWords = checkForBadWords(todoName);
            if (containsBadWords) {
                span.setAttribute("validation.result", "invalid_profanity");
                return ResponseEntity.ok(new ValidationResponse(false, "Todo name contains inappropriate content"));
            }
            
            // External service validation
            boolean externalValidation = performExternalValidation(todoName);
            if (!externalValidation) {
                span.setAttribute("validation.result", "invalid_external");
                return ResponseEntity.ok(new ValidationResponse(false, "External validation failed"));
            }
            
            span.setAttribute("validation.result", "valid");
            span.addEvent("Validation completed successfully");
            
            return ResponseEntity.ok(new ValidationResponse(true, "Todo name is valid"));
            
        } catch (Exception e) {
            span.recordException(e);
            span.setAttribute("validation.result", "error");
            return ResponseEntity.internalServerError()
                .body(new ValidationResponse(false, "Validation service error"));
        } finally {
            span.end();
        }
    }
    
    private boolean checkForBadWords(String todoName) {
        Span span = tracer.spanBuilder("check_bad_words")
            .setAttribute("todo.name", todoName)
            .startSpan();
        
        try {
            String lowerName = todoName.toLowerCase();
            boolean hasBadWords = lowerName.contains("bad") || 
                                lowerName.contains("terrible") || 
                                lowerName.contains("awful");
            
            span.setAttribute("bad_words.found", hasBadWords);
            span.addEvent("Bad words check completed");
            
            return hasBadWords;
        } finally {
            span.end();
        }
    }
    
    private boolean performExternalValidation(String todoName) {
        Span span = tracer.spanBuilder("external_validation")
            .setAttribute("external.service", "jsonplaceholder")
            .setAttribute("todo.name", todoName)
            .startSpan();
        
        try {
            // Simulate external validation by fetching a user
            String response = webClient
                .get()
                .uri("/users/1")
                .retrieve()
                .bodyToMono(String.class)
                .timeout(Duration.ofSeconds(3))
                .doOnSuccess(res -> span.addEvent("External service call successful"))
                .doOnError(err -> span.recordException(err))
                .onErrorReturn("")
                .block();
            
            boolean isValid = response != null && !response.isEmpty();
            span.setAttribute("external.validation.result", isValid);
            
            return isValid;
            
        } finally {
            span.end();
        }
    }
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "UP", "service", "validation-service"));
    }
}