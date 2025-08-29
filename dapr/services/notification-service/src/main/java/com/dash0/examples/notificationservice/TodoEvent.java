package com.dash0.examples.notificationservice;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * TodoEvent represents an event from the todo service
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoEvent {
    @JsonProperty("eventType")
    private String type;
    
    @JsonProperty("todoId")
    private String todoId;
    
    @JsonProperty("todoName")
    private String todoName;
    
    @JsonProperty("timestamp")
    private String timestamp;
    
    @JsonProperty("userId")
    private String userId;
    
    @JsonProperty("validatedBy")
    private String validatedBy;
    
    @JsonProperty("traceparent")
    private String traceParent;
}