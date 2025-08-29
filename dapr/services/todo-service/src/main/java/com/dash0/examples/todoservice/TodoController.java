package com.dash0.examples.todoservice;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import jakarta.validation.Valid;
import java.util.Map;

/**
 * REST Controller for Todo operations.
 */
@RestController
@RequestMapping("/todos")
public class TodoController {

    private static final Logger log = LoggerFactory.getLogger(TodoController.class);
    private final TodoService todoService;
    
    public TodoController(TodoService todoService) {
        this.todoService = todoService;
    }

    /**
     * Get all todos.
     * GET /todos
     */
    @GetMapping
    public Flux<Todo> getAllTodos() {
        log.info("GET /todos - Getting all todos");
        return todoService.getAllTodos();
    }

    /**
     * Get a specific todo by id.
     * GET /todos/{id}
     */
    @GetMapping("/{id}")
    public Mono<ResponseEntity<Todo>> getTodoById(@PathVariable String id) {
        log.info("GET /todos/{} - Getting todo by id", id);
        return todoService.getTodoById(id)
            .map(todo -> ResponseEntity.ok(todo))
            .onErrorReturn(TodoNotFoundException.class, ResponseEntity.notFound().build());
    }

    /**
     * Create a new todo.
     * POST /todos
     */
    @PostMapping
    public Mono<ResponseEntity<Todo>> createTodo(@Valid @RequestBody CreateTodoRequest request) {
        log.info("POST /todos - Creating new todo with name: {}", request.getName());
        return todoService.createTodo(request.getName())
            .map(todo -> ResponseEntity.status(HttpStatus.CREATED).body(todo))
            .onErrorReturn(IllegalArgumentException.class, 
                ResponseEntity.badRequest().build());
    }

    /**
     * Update a todo (toggle completion status).
     * PUT /todos/{id}
     */
    @PutMapping("/{id}")
    public Mono<ResponseEntity<Todo>> updateTodo(@PathVariable String id) {
        log.info("PUT /todos/{} - Updating todo", id);
        return todoService.updateTodo(id)
            .map(todo -> ResponseEntity.ok(todo))
            .onErrorReturn(TodoNotFoundException.class, ResponseEntity.notFound().build());
    }

    /**
     * Delete a todo.
     * DELETE /todos/{id}
     */
    @DeleteMapping("/{id}")
    public Mono<ResponseEntity<Void>> deleteTodo(@PathVariable String id) {
        log.info("DELETE /todos/{} - Deleting todo", id);
        return todoService.deleteTodo(id)
            .then(Mono.just(ResponseEntity.noContent().<Void>build()))
            .onErrorReturn(TodoNotFoundException.class, ResponseEntity.notFound().build());
    }

    /**
     * Health check endpoint.
     * GET /todos/health
     */
    @GetMapping("/health")
    public Mono<ResponseEntity<Map<String, String>>> health() {
        return Mono.just(ResponseEntity.ok(Map.of("status", "UP", "service", "todo-service")));
    }

    /**
     * Request object for creating a new todo.
     */
    public static class CreateTodoRequest {
        private String name;
        
        public CreateTodoRequest() {}
        
        public CreateTodoRequest(String name) {
            this.name = name;
        }
        
        public String getName() {
            return name;
        }
        
        public void setName(String name) {
            this.name = name;
        }
    }

    /**
     * Global exception handler for the controller.
     */
    @ExceptionHandler(TodoNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleTodoNotFound(TodoNotFoundException e) {
        log.error("Todo not found: {}", e.getMessage());
        return ResponseEntity.notFound().build();
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgument(IllegalArgumentException e) {
        log.error("Invalid argument: {}", e.getMessage());
        return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGenericException(Exception e) {
        log.error("Unexpected error occurred", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(Map.of("error", "Internal server error"));
    }
}