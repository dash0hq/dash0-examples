package com.dash0.examples.todoservice;

import io.dapr.client.DaprClient;
import io.dapr.client.DaprClientBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

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

    /**
     * Configure DaprClient bean.
     */
    @Bean
    public DaprClient daprClient() {
        log.info("Creating DaprClient bean...");
        return new DaprClientBuilder().build();
    }
}