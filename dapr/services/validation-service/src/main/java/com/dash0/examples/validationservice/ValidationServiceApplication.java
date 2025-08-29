package com.dash0.examples.validationservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;

@SpringBootApplication
public class ValidationServiceApplication {

    public static void main(String[] args) {
        System.out.println("=== OpenTelemetry Environment Variables ===");
        System.out.println("JAVA_TOOL_OPTIONS: " + System.getenv("JAVA_TOOL_OPTIONS"));
        System.out.println("OTEL_SERVICE_NAME: " + System.getenv("OTEL_SERVICE_NAME"));
        System.out.println("OTEL_PROPAGATORS: " + System.getenv("OTEL_PROPAGATORS"));
        System.out.println("OTEL_LOG_LEVEL: " + System.getenv("OTEL_LOG_LEVEL"));
        System.out.println("OTEL_TRACES_EXPORTER: " + System.getenv("OTEL_TRACES_EXPORTER"));
        System.out.println("OTEL_EXPORTER_OTLP_PROTOCOL: " + System.getenv("OTEL_EXPORTER_OTLP_PROTOCOL"));
        System.out.println("OTEL_EXPORTER_OTLP_ENDPOINT: " + System.getenv("OTEL_EXPORTER_OTLP_ENDPOINT"));
        System.out.println("===========================================");
        
        SpringApplication.run(ValidationServiceApplication.class, args);
    }

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}