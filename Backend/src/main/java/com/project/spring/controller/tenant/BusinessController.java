package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.BusinessDTO;
import com.project.spring.dto.DashboardDetailsDTO;
import com.project.spring.model.tenant.Business;
import com.project.spring.repo.tenant.TenantBusinessRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@RestController
@RequestMapping("/api/v1/business")
public class BusinessController {

    @Autowired
    private TenantBusinessRepository businessRepository;

    // Get all businesses
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<BusinessDTO>>> getAllBusinesses() {
        try {
            List<BusinessDTO> businesses = StreamSupport
                    .stream(businessRepository.findAll().spliterator(), false)
                    .map(this::mapToDTO)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(
                    new ApiResponse<>("success", "Businesses fetched successfully", businesses));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error fetching businesses: " + e.getMessage(), null));
        }
    }
    @GetMapping("/dashboard/showMe")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<DashboardDetailsDTO>> getDashboardDetails() {
        try {
            // Get authenticated user's info
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            String role = authentication.getAuthorities()
                    .stream()
                    .map(GrantedAuthority::getAuthority)
                    .map(r -> r.replace("ROLE_", ""))
                    .findFirst()
                    .orElse("USER");

            // Fetch business with ID = 1
            Business business = businessRepository.findById(1L).orElse(null);
            if (business == null) {
                return ResponseEntity.status(404).body(
                        new ApiResponse<>("failure", "Business with ID 1 not found", null));
            }

            // Build DTO
            DashboardDetailsDTO dto = new DashboardDetailsDTO(username, role, business.getName());

            return ResponseEntity.ok(
                    new ApiResponse<>("success", "Dashboard details fetched successfully", dto)
            );

        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error fetching dashboard details: " + e.getMessage(), null));
        }
    }



    

    // Get business by ID
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<ApiResponse<BusinessDTO>> getBusinessById(@PathVariable Long id) {
        try {
            return businessRepository.findById(id)
                    .map(business -> ResponseEntity.ok(
                            new ApiResponse<>("success", "Business found", mapToDTO(business))))
                    .orElse(ResponseEntity.status(404).body(
                            new ApiResponse<>("failure", "Business not found", null)));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error fetching business: " + e.getMessage(), null));
        }
    }

    // Add new business
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<ApiResponse<BusinessDTO>> addBusiness(@RequestBody Business business) {
        try {
            Business saved = businessRepository.save(business);
            return ResponseEntity.ok(
                    new ApiResponse<>("success", "Business added successfully", mapToDTO(saved)));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error adding business: " + e.getMessage(), null));
        }
    }

    // Update business
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<ApiResponse<BusinessDTO>> updateBusiness(@PathVariable Long id, @RequestBody Business updatedBusiness) {
        try {
            return businessRepository.findById(id).map(existing -> {
                existing.setName(updatedBusiness.getName());
                existing.setGstNumber(updatedBusiness.getGstNumber());
                existing.setAddress(updatedBusiness.getAddress());
                existing.setLogoUrl(updatedBusiness.getLogoUrl());
                existing.setFssaiNo(updatedBusiness.getFssaiNo());
                existing.setLicenceNo(updatedBusiness.getLicenceNo());
                existing.setGstType(updatedBusiness.getGstType());
                existing.setPhoneNo(updatedBusiness.getPhoneNo());
                existing.setEmail(updatedBusiness.getEmail());
                existing.setTableCount(updatedBusiness.getTableCount());

                Business saved = businessRepository.save(existing);
                return ResponseEntity.ok(
                        new ApiResponse<>("success", "Business updated successfully", mapToDTO(saved)));
            }).orElse(ResponseEntity.status(404).body(
                    new ApiResponse<>("failure", "Business not found", null)));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error updating business: " + e.getMessage(), null));
        }
    }

    // Delete business
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> deleteBusiness(@PathVariable Long id) {
        try {
            if (businessRepository.existsById(id)) {
                businessRepository.deleteById(id);
                return ResponseEntity.ok(
                        new ApiResponse<>("success", "Business deleted successfully", null));
            } else {
                return ResponseEntity.status(404).body(
                        new ApiResponse<>("failure", "Business not found", null));
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    new ApiResponse<>("failure", "Error deleting business: " + e.getMessage(), null));
        }
    }

    // Mapper
    private BusinessDTO mapToDTO(Business business) {
        BusinessDTO dto = new BusinessDTO();
        dto.setId(business.getId());
        dto.setName(business.getName());
        dto.setGstNumber(business.getGstNumber());
        dto.setAddress(business.getAddress());
        dto.setLogoUrl(business.getLogoUrl());
        dto.setFssaiNo(business.getFssaiNo());
        dto.setLicenceNo(business.getLicenceNo());
        dto.setGstType(business.getGstType());
        dto.setPhoneNo(business.getPhoneNo());
        dto.setEmail(business.getEmail());
        dto.setTableCount(business.getTableCount());
        return dto;
    }
}
