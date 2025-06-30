package xyz.kaspernissen.todo_java;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.metrics.LongCounter;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.Span;

@RestController
@RequestMapping("/todos")
public class TodoController {

    private final TodoRepository repository;
    private final ValidationService validationService;
    private final Tracer tracer;
    private final LongCounter todoCreatedCounter;

    public TodoController(TodoRepository repository, ValidationService validationService) {
        this.repository = repository;
        this.validationService = validationService;
        
        OpenTelemetry openTelemetry = GlobalOpenTelemetry.get();
        this.tracer = openTelemetry.getTracer("todo-controller");
        this.todoCreatedCounter = openTelemetry.getMeter("todo-controller")
            .counterBuilder("todos.created")
            .setDescription("Number of todos created")
            .build();
    }

    @GetMapping
    public Page<Todo> getAllTodos(Pageable pageable) {
        return repository.findAll(pageable);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Todo> getTodoById(@PathVariable Long id) {
        if (id == null || id <= 0) {
            return ResponseEntity.badRequest().build();
        }
        return repository.findById(id)
                .map(ResponseEntity::ok)
                .orElseThrow(() -> new ResourceNotFoundException("Todo not found with id: " + id));
    }

    @PostMapping
    public ResponseEntity<Todo> createTodo(@Valid @RequestBody Todo todo) {
        Span span = tracer.spanBuilder("create_todo").startSpan();
        
        try {
            if (todo.getName() == null || todo.getName().trim().isEmpty()) {
                span.addEvent("Invalid todo name provided");
                return ResponseEntity.badRequest().build();
            }
            
            todo.setId(null);
            String todoName = todo.getName().trim();
            
            span.setAttribute("todo.name", todoName);
            span.setAttribute("todo.name.length", todoName.length());
            
            // Validate todo name using external service (creates distributed trace)
            if (!validationService.isValidTodoName(todoName)) {
                span.addEvent("Todo name validation failed");
                span.setAttribute("validation.failed", true);
                return ResponseEntity.badRequest().body(null);
            }
            
            span.addEvent("Todo name validation passed");
            Todo savedTodo = repository.save(todo);
            
            todoCreatedCounter.add(1);
            span.addEvent("Todo created successfully");
            
            return ResponseEntity.status(HttpStatus.CREATED).body(savedTodo);
            
        } catch (Exception e) {
            span.recordException(e);
            throw e;
        } finally {
            span.end();
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<Todo> updateTodo(@PathVariable Long id, @Valid @RequestBody Todo todoDetails) {
        if (id == null || id <= 0) {
            return ResponseEntity.badRequest().build();
        }
        if (todoDetails.getName() == null || todoDetails.getName().trim().isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        return repository.findById(id)
                .map(todo -> {
                    todo.setName(todoDetails.getName().trim());
                    return ResponseEntity.ok(repository.save(todo));
                })
                .orElseThrow(() -> new ResourceNotFoundException("Todo not found with id: " + id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTodo(@PathVariable Long id) {
        if (id == null || id <= 0) {
            return ResponseEntity.badRequest().build();
        }
        Todo todo = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Todo not found with id: " + id));
        repository.delete(todo);
        return ResponseEntity.noContent().build();
    }
}