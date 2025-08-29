package com.dash0.examples.todoservice;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;

/**
 * Event object for todo operations.
 */
public class TodoEvent {
    
    @JsonProperty("eventType")
    private String eventType;
    
    @JsonProperty("todo")
    private Todo todo;
    
    @JsonProperty("timestamp")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime timestamp;
    
    public TodoEvent() {
    }
    
    public TodoEvent(String eventType, Todo todo, LocalDateTime timestamp) {
        this.eventType = eventType;
        this.todo = todo;
        this.timestamp = timestamp;
    }
    
    public TodoEvent(String eventType, Todo todo) {
        this.eventType = eventType;
        this.todo = todo;
        this.timestamp = LocalDateTime.now();
    }
    
    // Getters and Setters
    public String getEventType() {
        return eventType;
    }
    
    public void setEventType(String eventType) {
        this.eventType = eventType;
    }
    
    public Todo getTodo() {
        return todo;
    }
    
    public void setTodo(Todo todo) {
        this.todo = todo;
    }
    
    public LocalDateTime getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
    
    @Override
    public String toString() {
        return "TodoEvent{" +
                "eventType='" + eventType + '\'' +
                ", todo=" + todo +
                ", timestamp=" + timestamp +
                '}';
    }
}