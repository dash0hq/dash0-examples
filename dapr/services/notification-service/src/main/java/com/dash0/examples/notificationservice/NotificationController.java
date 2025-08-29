package com.dash0.examples.notificationservice;

import io.dapr.Topic;
import io.dapr.client.domain.CloudEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * NotificationController handles Dapr PubSub events only
 */
@RestController
@RequiredArgsConstructor
@Slf4j
public class NotificationController {

    private final NotificationService notificationService;

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "service", "notification-service",
            "timestamp", LocalDateTime.now()
        ));
    }

    /**
     * Dapr PubSub event subscriber for todo events
     */
    @Topic(name = "todo-events", pubsubName = "todo-pubsub")
    @PostMapping("/subscribe")
    public Mono<ResponseEntity<Map<String, String>>> handleTodoEvent(@RequestBody CloudEvent<TodoEvent> cloudEvent) {
        log.info("Received CloudEvent - ID: {}, Source: {}, Type: {}", 
                 cloudEvent.getId(), cloudEvent.getSource(), cloudEvent.getType());
        
        TodoEvent todoEvent = cloudEvent.getData();
        if (todoEvent != null) {
            log.info("Processing todo event: {} for todo {}", todoEvent.getType(), todoEvent.getTodoId());
            
            return notificationService.processTodoEvent(todoEvent)
                .map(result -> ResponseEntity.ok(Map.of("status", "processed")))
                .onErrorReturn(ResponseEntity.ok(Map.of("status", "retry")));
        } else {
            log.warn("Received CloudEvent with null data");
            return Mono.just(ResponseEntity.badRequest().body(Map.of("error", "Invalid event data")));
        }
    }
}