package com.project.spring.controller.master;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.OtpDTO;
import com.project.spring.service.master.OtpService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth/otp")
public class OtpController {

    private final OtpService otpService;

    public OtpController(OtpService otpService) {
        this.otpService = otpService;
    }

    @PostMapping("/send")
    public ResponseEntity<ApiResponse<String>> sendOtp(@RequestBody OtpDTO dto) {
        try {
            otpService.sendOtp(dto.getPhoneNo());
            return ResponseEntity.ok(
                new ApiResponse<>("success", "OTP sent successfully", null)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to send OTP: " + e.getMessage(), null)
            );
        }
    }

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<String>> verifyOtp(@RequestBody OtpDTO dto) {
        try {
            boolean isValid = otpService.verifyOtp(dto.getPhoneNo(), dto.getOtp());
            if (isValid) {
                return ResponseEntity.ok(
                    new ApiResponse<>("success", "OTP verified successfully", null)
                );
            } else {
                return ResponseEntity.badRequest().body(
                    new ApiResponse<>("failure", "Invalid OTP", null)
                );
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "OTP verification failed: " + e.getMessage(), null)
            );
        }
    }
}