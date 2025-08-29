package com.dash0.examples.todoservice;

import io.dapr.client.DaprClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Service layer for Todo operations.
 */
@Service
public class TodoService {

    private static final Logger log = LoggerFactory.getLogger(TodoService.class);
    private static final String VALIDATION_SERVICE_APP_ID = "validation-service";
    private static final String PUBSUB_NAME = "todo-pubsub";
    private static final String TOPIC_NAME = "todo-events";

    private final TodoRepository todoRepository;
    private final DaprClient daprClient;
    
    public TodoService(TodoRepository todoRepository, DaprClient daprClient) {
        this.todoRepository = todoRepository;
        this.daprClient = daprClient;
    }

    /**
     * Create a new todo after validation.
     */
    public Mono<Todo> createTodo(String name) {
        log.info("Creating todo with name: {}", name);
        
        return validateTodoName(name)
            .flatMap(isValid -> {
                if (!isValid) {
                    return Mono.error(new IllegalArgumentException("Todo name is invalid"));
                }
                
                Todo todo = new Todo(name);
                return todoRepository.save(todo)
                    .doOnNext(savedTodo -> {
                        log.info("Todo saved successfully: {}", savedTodo.getId());
                        // Publish event after save
                        publishTodoEvent("created", savedTodo);
                    });
            });
    }

    /**
     * Get all todos.
     */
    public Flux<Todo> getAllTodos() {
        log.info("Getting all todos");
        return todoRepository.findAll();
    }

    /**
     * Get a todo by id.
     */
    public Mono<Todo> getTodoById(String id) {
        log.info("Getting todo with id: {}", id);
        return todoRepository.findById(id)
            .switchIfEmpty(Mono.error(new TodoNotFoundException("Todo with id " + id + " not found")));
    }

    /**
     * Update a todo (toggle completion status).
     */
    public Mono<Todo> updateTodo(String id) {
        log.info("Updating todo with id: {}", id);
        
        return todoRepository.findById(id)
            .switchIfEmpty(Mono.error(new TodoNotFoundException("Todo with id " + id + " not found")))
            .flatMap(todo -> {
                todo.toggleCompleted();
                return todoRepository.save(todo)
                    .doOnNext(savedTodo -> {
                        publishTodoEvent("updated", savedTodo);
                    });
            });
    }

    /**
     * Delete a todo by id.
     */
    public Mono<Void> deleteTodo(String id) {
        log.info("Deleting todo with id: {}", id);
        
        return todoRepository.findById(id)
            .switchIfEmpty(Mono.error(new TodoNotFoundException("Todo with id " + id + " not found")))
            .flatMap(todo -> {
                return todoRepository.deleteById(id)
                    .then(Mono.fromRunnable(() -> publishTodoEvent("deleted", todo)));
            });
    }

    /**
     * Validate todo name using the validation service via Dapr service invocation.
     */
    private Mono<Boolean> validateTodoName(String name) {
        log.info("Validating todo name: {}", name);
        
        Map<String, String> validationRequest = new HashMap<>();
        validationRequest.put("name", name);
        
        return daprClient.invokeMethod(
            VALIDATION_SERVICE_APP_ID,
            "validate",
            validationRequest,
            io.dapr.client.domain.HttpExtension.POST,
            ValidationResponse.class
        )
        .map(ValidationResponse::isValid)
        .doOnError(error -> log.error("Validation service call failed", error))
        .onErrorReturn(true); // Default to valid if validation service is unavailable
    }

    /**
     * Publish todo events to Dapr pubsub.
     */
    private void publishTodoEvent(String eventType, Todo todo) {
        try {
            log.info("Publishing {} event for todo: {}", eventType, todo.getId());
            
            // Create event matching notification-service expected format
            Map<String, Object> event = new HashMap<>();
            event.put("eventType", eventType);
            event.put("todoId", todo.getId());
            event.put("todoName", todo.getName());
            event.put("timestamp", LocalDateTime.now().toString());
            event.put("userId", "demo-user");
            event.put("validatedBy", "validation-service");
            
            // Simple blocking call with try-catch
            daprClient.publishEvent(
                PUBSUB_NAME,
                TOPIC_NAME, 
                event
            ).block();
            
            log.info("Successfully published {} event for todo {} to topic {}", 
                     eventType, todo.getId(), TOPIC_NAME);
        } catch (Exception e) {
            log.error("Error publishing event to pubsub: {}", e.getMessage(), e);
            // Continue processing even if publishing fails
        }
    }

    /**
     * Validation response from validation service.
     */
    public static class ValidationResponse {
        private boolean valid;
        
        public ValidationResponse() {}
        
        public ValidationResponse(boolean valid) {
            this.valid = valid;
        }
        
        public boolean isValid() {
            return valid;
        }
        
        public void setValid(boolean valid) {
            this.valid = valid;
        }
    }
}