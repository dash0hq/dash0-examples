package com.dash0.examples.notificationservice;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * NotificationPreferences represents user notification settings
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class NotificationPreferences {
    @JsonProperty("userId")
    private String userId;
    
    @JsonProperty("email")
    private String email;
    
    @JsonProperty("enabledEvents")
    private List<String> enabledEvents;
    
    @JsonProperty("emailNotifications")
    private boolean emailNotifications;
    
    @JsonProperty("createdAt")
    private LocalDateTime createdAt;
    
    @JsonProperty("updatedAt")
    private LocalDateTime updatedAt;
}