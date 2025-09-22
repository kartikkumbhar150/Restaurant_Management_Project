package com.project.spring.dto;

public class DashboardDetailsDTO {
    private String username;
    private String role;
    private String businessName;
    private String logoUrl;

    // Constructors
    public DashboardDetailsDTO() {}

    public DashboardDetailsDTO(String username, String role, String businessName, String logoUrl) {
        this.username = username;
        this.role = role;
        this.businessName = businessName;
        this.logoUrl = logoUrl;
    
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
    public String getLogoUrl(){
        return logoUrl;
    }
    public void setLogoUrl(String logoUrl){
        this.logoUrl = logoUrl;
    }
}
