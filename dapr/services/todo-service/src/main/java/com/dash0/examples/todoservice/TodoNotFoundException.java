package com.dash0.examples.todoservice;

/**
 * Exception thrown when a todo is not found.
 */
public class TodoNotFoundException extends RuntimeException {
    
    public TodoNotFoundException(String message) {
        super(message);
    }
    
    public TodoNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
}