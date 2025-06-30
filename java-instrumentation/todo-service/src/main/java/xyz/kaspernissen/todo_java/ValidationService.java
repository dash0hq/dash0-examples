package xyz.kaspernissen.todo_java;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.Span;

import java.time.Duration;

@Service
public class ValidationService {
    
    private final WebClient webClient;
    private final Tracer tracer;
    
    public ValidationService(WebClient.Builder webClientBuilder, 
                           @Value("${validation.service.url:http://localhost:3001}") String validationServiceUrl) {
        this.webClient = webClientBuilder
            .baseUrl(validationServiceUrl)
            .build();
        this.tracer = GlobalOpenTelemetry.get().getTracer("todo-service-validation-client");
    }
    
    public boolean isValidTodoName(String todoName) {
        Span span = tracer.spanBuilder("call_validation_service")
            .setAttribute("todo.name", todoName)
            .setAttribute("service.call", "validation-service")
            .startSpan();
        
        try {
            ValidationRequest request = new ValidationRequest(todoName);
            
            ValidationResponse response = webClient
                .post()
                .uri("/validate/todo-name")
                .bodyValue(request)
                .retrieve()
                .bodyToMono(ValidationResponse.class)
                .timeout(Duration.ofSeconds(5))
                .doOnSuccess(res -> span.addEvent("Validation service responded"))
                .doOnError(err -> span.recordException(err))
                .onErrorReturn(new ValidationResponse(false, "Validation service error"))
                .block();
            
            boolean isValid = response != null && response.isValid();
            span.setAttribute("validation.result", isValid);
            if (response != null) {
                span.setAttribute("validation.message", response.getMessage());
            }
            
            return isValid;
            
        } catch (Exception e) {
            span.recordException(e);
            span.setAttribute("validation.result", false);
            return false;
        } finally {
            span.end();
        }
    }
}