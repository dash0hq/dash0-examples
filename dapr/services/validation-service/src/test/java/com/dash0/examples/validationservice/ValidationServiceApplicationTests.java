package com.dash0.examples.validationservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

/**
 * Basic integration test for the ValidationServiceApplication
 */
@SpringBootTest
@TestPropertySource(properties = {
    "dapr.statestore.name=test-statestore",
    "dapr.binding.name=test-binding"
})
class ValidationServiceApplicationTests {

    @Test
    void contextLoads() {
        // This test verifies that the Spring Boot context loads successfully
    }

}