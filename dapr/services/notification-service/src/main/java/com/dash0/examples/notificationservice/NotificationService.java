package com.dash0.examples.notificationservice;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

/**
 * NotificationService handles todo events by simply logging them
 */
@Service
@Slf4j
public class NotificationService {

    /**
     * Process todo events and log them
     */
    public Mono<String> processTodoEvent(TodoEvent event) {
        log.info("📧 NOTIFICATION: Todo '{}' (ID: {}) was {} at {} by user {}",
                event.getTodoName(),
                event.getTodoId(),
                event.getType(),
                event.getTimestamp(),
                event.getUserId());
        
        // Simulate some processing
        return Mono.just("processed");
    }
}