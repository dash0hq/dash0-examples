package com.dash0.examples.todoservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "dapr.statestore.name=test-statestore",
    "dapr.pubsub.name=test-pubsub"
})
class TodoServiceApplicationTests {

    @Test
    void contextLoads() {
        // This test verifies that the Spring context loads successfully
    }
}