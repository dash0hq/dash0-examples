package com.dash0.examples.notificationservice;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * UserPreferencesRequest represents a request to update user preferences
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserPreferencesRequest {
    @JsonProperty("email")
    private String email;
    
    @JsonProperty("enabledEvents")
    private List<String> enabledEvents;
    
    @JsonProperty("emailNotifications")
    private boolean emailNotifications;
}