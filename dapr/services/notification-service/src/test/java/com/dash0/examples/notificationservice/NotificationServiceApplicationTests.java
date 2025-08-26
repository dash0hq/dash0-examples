package com.dash0.examples.notificationservice;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.dapr.client.DaprClient;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "dapr.statestore.name=test-statestore",
    "dapr.pubsub.name=test-pubsub",
    "dapr.binding.analytics.name=test-analytics-binding"
})
class NotificationServiceApplicationTests {

    @MockBean
    private DaprClient daprClient;

    @MockBean
    private ObjectMapper objectMapper;

    @Test
    void contextLoads() {
        // This test verifies that the Spring context loads successfully with mocked dependencies
    }
}