package com.project.spring.controller.master;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.project.spring.dto.ApiResponse;
import com.project.spring.model.master.StaffUser;
import com.project.spring.service.master.StaffUserService;

@RestController
@RequestMapping("/api/v1/auth")
public class LoginController {

    private final StaffUserService staffUserService;

    public LoginController(StaffUserService staffUserService) {
        this.staffUserService = staffUserService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<String>> login(@RequestBody StaffUser user) {
        try {
            // ✅ Delegate authentication + token persistence to service
            String token = staffUserService.verify(user);

            if ("fail".equals(token)) {
                return ResponseEntity.status(401).body(
                    new ApiResponse<>("failure", "Invalid username or password", null)
                );
            }

            return ResponseEntity.ok(
                new ApiResponse<>("success", "Login successful", token)
            );
        } catch (Exception ex) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Login failed: " + ex.getMessage(), null)
            );
        }
    }
}
