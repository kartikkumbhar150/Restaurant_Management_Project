package com.project.spring.controller.master;

import com.project.spring.dto.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public ResponseEntity<ApiResponse<String>> greet(HttpServletRequest request) {
        try {
            String welcomeMessage = "Welcome to the Restaurant Management System";
            return ResponseEntity.ok(
                new ApiResponse<>("success", "Greeting successful", welcomeMessage)
            );
        } catch (Exception e) {
            return ResponseEntity
                .badRequest()
                .body(new ApiResponse<>("failure", "Greeting failed: " + e.getMessage(), null));
        }
    }
}
