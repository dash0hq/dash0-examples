package com.dash0.examples.notificationservice;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * NotificationHistory represents a sent notification record
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class NotificationHistory {
    @JsonProperty("id")
    private String id;
    
    @JsonProperty("userId")
    private String userId;
    
    @JsonProperty("todoId")
    private String todoId;
    
    @JsonProperty("eventType")
    private String eventType;
    
    @JsonProperty("notificationType")
    private String notificationType;
    
    @JsonProperty("status")
    private String status;
    
    @JsonProperty("sentAt")
    private LocalDateTime sentAt;
    
    @JsonProperty("error")
    private String error;
}