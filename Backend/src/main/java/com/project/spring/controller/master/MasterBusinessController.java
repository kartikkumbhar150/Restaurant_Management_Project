package com.project.spring.controller.master;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.MasterBusinessDTO;

import com.project.spring.service.master.BusinessProvisionService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor      
public class MasterBusinessController {

    private final BusinessProvisionService businessProvisionService;
    
    
    /** Register a new business and create its tenant DB */
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<String>> registerBusiness(@RequestBody MasterBusinessDTO dto) {
        try {
            String dbName = businessProvisionService.createBusiness(
                    dto.getBusinessName(),
                    dto.getPassword(),
                    dto.getDbName(),
                    dto.getOwnerName(),
                    dto.getUserName(),
                    dto.getPhoneNo(),
                    dto.getEmail()
            );

            return ResponseEntity.ok(
                new ApiResponse<>("success", "Business registered successfully", dbName)
            );
        } catch (Exception ex) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Business registration failed: " + ex.getMessage(), null)
            );
        }
    }
}
