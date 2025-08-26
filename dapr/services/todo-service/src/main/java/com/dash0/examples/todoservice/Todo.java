package com.dash0.examples.todoservice;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * Todo entity representing a todo item.
 */
public class Todo {
    
    @JsonProperty("id")
    private String id;
    
    @NotBlank(message = "Name is required")
    @Size(max = 500, message = "Name must not exceed 500 characters")
    @JsonProperty("name")
    private String name;
    
    @JsonProperty("completed")
    private Boolean completed = false;
    
    @JsonProperty("createdAt")
    private String createdAt;
    
    @JsonProperty("updatedAt")  
    private String updatedAt;
    
    /**
     * Default constructor.
     */
    public Todo() {
    }
    
    /**
     * Constructor for creating a new Todo with a name.
     * Sets default values for id, completed status, and timestamps.
     */
    public Todo(String name) {
        this.id = UUID.randomUUID().toString();
        this.name = name;
        this.completed = false;
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"));
        this.updatedAt = now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"));
    }
    
    /**
     * Full constructor.
     */
    public Todo(String id, String name, Boolean completed, String createdAt, String updatedAt) {
        this.id = id;
        this.name = name;
        this.completed = completed;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
    
    /**
     * Updates the todo's updatedAt timestamp.
     */
    public void touch() {
        this.updatedAt = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"));
    }
    
    /**
     * Toggles the completed status and updates the timestamp.
     */
    public void toggleCompleted() {
        this.completed = !this.completed;
        touch();
    }
    
    // Getters and Setters
    public String getId() {
        return id;
    }
    
    public void setId(String id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public Boolean getCompleted() {
        return completed;
    }
    
    public void setCompleted(Boolean completed) {
        this.completed = completed;
    }
    
    public String getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
    
    public String getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    @Override
    public String toString() {
        return "Todo{" +
                "id='" + id + '\'' +
                ", name='" + name + '\'' +
                ", completed=" + completed +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
}