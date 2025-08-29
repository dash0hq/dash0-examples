package com.dash0.examples.todoservice;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main Spring Boot application class for Todo Service.
 */
@SpringBootApplication
public class TodoServiceApplication {

    private static final Logger log = LoggerFactory.getLogger(TodoServiceApplication.class);

    public static void main(String[] args) {
        log.info("Starting Todo Service Application...");
        SpringApplication.run(TodoServiceApplication.class, args);
        log.info("Todo Service Application started successfully!");
    }

}