package com.dash0.examples.todoservice;

import io.dapr.client.DaprClient;
import io.dapr.client.domain.State;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Repository for Todo entities using Dapr state store.
 */
@Repository
public class TodoRepository {

    private static final Logger log = LoggerFactory.getLogger(TodoRepository.class);
    private static final String STATE_STORE_NAME = "todo-statestore";
    private static final String TODO_KEY_PREFIX = "todo-";
    private static final String TODO_INDEX_KEY = "todo-index";
    
    private final DaprClient daprClient;
    
    // Local cache for todo IDs (in production, use Dapr query or maintain index in state store)
    private final ConcurrentHashMap<String, Boolean> todoIds = new ConcurrentHashMap<>();
    
    public TodoRepository(DaprClient daprClient) {
        this.daprClient = daprClient;
    }

    /**
     * Save a todo to the state store.
     */
    public Mono<Todo> save(Todo todo) {
        log.info("Saving todo with id: {}", todo.getId());
        
        String key = getKey(todo.getId());
        todoIds.put(todo.getId(), true);
        
        // Use Mono.fromRunnable to execute blocking operations
        return Mono.fromRunnable(() -> {
            try {
                // Block on save state - following Dapr SDK examples
                daprClient.saveState(STATE_STORE_NAME, key, todo).block();
                log.info("Todo saved to state store: {}", todo.getId());
                
                // Update index
                updateIndex(todo.getId(), true).block();
                log.info("Index updated for todo: {}", todo.getId());
            } catch (Exception e) {
                log.error("Failed to save todo: {}", e.getMessage(), e);
                throw new RuntimeException("Failed to save todo", e);
            }
        })
        .then(Mono.just(todo));
    }

    /**
     * Find a todo by id.
     */
    public Mono<Todo> findById(String id) {
        log.info("Finding todo with id: {}", id);
        
        String key = getKey(id);
        
        return daprClient.getState(STATE_STORE_NAME, key, Todo.class)
            .flatMap(state -> {
                Todo todo = state.getValue();
                if (todo != null) {
                    todoIds.put(id, true);
                    return Mono.just(todo);
                } else {
                    return Mono.empty();
                }
            });
    }

    /**
     * Find all todos.
     */
    public Flux<Todo> findAll() {
        log.info("Finding all todos");
        
        return getIndexFromStore()
            .flatMapMany(index -> {
                if (index.isEmpty()) {
                    log.info("No todos found in index");
                    return Flux.empty();
                }
                
                log.info("Found {} todo IDs in index", index.size());
                return Flux.fromIterable(index)
                    .flatMap(this::findById)
                    .filter(todo -> todo != null);
            });
    }

    /**
     * Delete a todo by id.
     */
    public Mono<Void> deleteById(String id) {
        log.info("Deleting todo with id: {}", id);
        
        String key = getKey(id);
        
        return daprClient.deleteState(STATE_STORE_NAME, key, null, null)
            .then(updateIndex(id, false))
            .doOnSuccess(v -> todoIds.remove(id));
    }

    /**
     * Check if a todo exists by id.
     */
    public Mono<Boolean> existsById(String id) {
        return findById(id)
            .map(todo -> todo != null)
            .defaultIfEmpty(false);
    }

    /**
     * Count all todos.
     */
    public Mono<Long> count() {
        return findAll().count();
    }

    /**
     * Delete all todos.
     */
    public Mono<Void> deleteAll() {
        log.info("Deleting all todos");
        
        return findAll()
            .map(Todo::getId)
            .flatMap(this::deleteById)
            .then();
    }

    private String getKey(String id) {
        return TODO_KEY_PREFIX + id;
    }

    /**
     * Update the todo index in state store.
     */
    private Mono<Void> updateIndex(String todoId, boolean add) {
        return getIndexFromStore()
            .map(index -> {
                if (add) {
                    index.add(todoId);
                } else {
                    index.remove(todoId);
                }
                return index;
            })
            .flatMap(updatedIndex -> 
                daprClient.saveState(STATE_STORE_NAME, TODO_INDEX_KEY, updatedIndex)
            );
    }

    /**
     * Get todo index from state store.
     */
    private Mono<Set<String>> getIndexFromStore() {
        return daprClient.getState(STATE_STORE_NAME, TODO_INDEX_KEY, HashSet.class)
            .map(state -> {
                @SuppressWarnings("unchecked")
                HashSet<String> index = (HashSet<String>) state.getValue();
                return (Set<String>) (index != null ? index : new HashSet<String>());
            })
            .onErrorReturn(new HashSet<String>());
    }
}