package com.project.spring.controller.master;
import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.OtpDTO;
import com.project.spring.dto.UpdatePasswordDTO;
import com.project.spring.service.master.ForgotPasswordService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/v1/auth")
public class ForgotPasswordController {
    private final ForgotPasswordService otpService;

    public ForgotPasswordController(ForgotPasswordService service){
        this.otpService = service;
    }
    @PostMapping("/forgot-password/otp/send")
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
    @PostMapping("/forgot-password/otp/verify")
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

    @PutMapping("/change-password")
    public ResponseEntity<ApiResponse<String>> updatePassword(@RequestBody UpdatePasswordDTO dto) {
        try {
            boolean updated = otpService.updatePassword(dto.getUserName(), dto.getNewPassword());
            if (updated) {
                return ResponseEntity.ok(
                    new ApiResponse<>("success", "Password updated successfully", null)
                );
            } else {
                return ResponseEntity.badRequest().body(
                    new ApiResponse<>("failure", "Failed to update password", null)
                );
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Password update failed: " + e.getMessage(), null)
            );
        }
    }

}
