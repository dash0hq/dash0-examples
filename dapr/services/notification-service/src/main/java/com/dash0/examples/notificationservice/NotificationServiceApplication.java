package com.dash0.examples.notificationservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import io.dapr.client.DaprClient;
import io.dapr.client.DaprClientBuilder;

/**
 * Main Spring Boot Application class for the Notification Service
 */
@SpringBootApplication
public class NotificationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(NotificationServiceApplication.class, args);
    }

    @Bean
    public DaprClient daprClient() {
        return new DaprClientBuilder().build();
    }
}