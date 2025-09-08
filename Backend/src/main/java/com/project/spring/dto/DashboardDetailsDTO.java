package com.project.spring.dto;

public class DashboardDetailsDTO {
    private String username;
    private String role;
    private String businessName;

    // Constructors
    public DashboardDetailsDTO() {}

    public DashboardDetailsDTO(String username, String role, String businessName) {
        this.username = username;
        this.role = role;
        this.businessName = businessName;
    }

    // Getters and Setters
    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getBusinessName() {
        return businessName;
    }

    public void setBusinessName(String businessName) {
        this.businessName = businessName;
    }
}
