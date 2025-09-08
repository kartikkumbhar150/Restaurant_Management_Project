package com.project.spring.service.master;

import com.project.spring.config.TenantContext;
import com.project.spring.dto.StaffDTO;
import com.project.spring.model.master.MasterBusiness;
import com.project.spring.model.master.StaffUser;
import com.project.spring.model.tenant.Staff;
import com.project.spring.repo.master.MasterBusinessRepository;
import com.project.spring.repo.master.StaffUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class StaffUserService {

    private final MasterBusinessRepository businessRepository;
    private final StaffUserRepository staffUserRepository;
    private final JWTService jwtService;
    private final AuthenticationManager authManager;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);

    public void saveStaffToMaster(Staff staff, Long businessId) {
        String originalTenant = TenantContext.getCurrentTenant();
        try {
            TenantContext.clear(); // Switch to master DB

            MasterBusiness business = businessRepository.findById(businessId)
                    .orElseThrow(() -> new RuntimeException("Business not found"));

            StaffUser user = staffUserRepository.findByUserName(staff.getUserName())
                    .orElse(new StaffUser());

            user.setName(staff.getName());
            user.setUserName(staff.getUserName());
            user.setRole(staff.getRole());
            user.setPassword(encoder.encode(staff.getPassword())); // Always encode
            user.setDbName(business.getDbName());

            staffUserRepository.saveAndFlush(user);
        } finally {
            restoreTenant(originalTenant);
        }
    }

    public String verify(StaffUser user) {
        Authentication authentication = authManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        user.getUserName(),
                        user.getPassword()
                )
        );

        if (authentication.isAuthenticated()) {
            StaffUser dbUser = findByUserName(user.getUserName());
            if (dbUser != null) {
                return generateToken(
                        dbUser.getUserName(),
                        dbUser.getRole(),
                        dbUser.getDbName()
                );
            }
        }
        return "fail";
    }

    public StaffUser findByUserName(String username) {
        return staffUserRepository.findByUserName(username).orElse(null);
    }

    public boolean checkPassword(String rawPassword, String encodedPassword) {
        return encoder.matches(rawPassword, encodedPassword);
    }

    public String generateToken(String username, String role, String dbName) {
        return jwtService.generateToken(username, role, dbName);
    }

    public void deleteStaffFromMaster(Long staffId) {
        String originalTenant = TenantContext.getCurrentTenant();
        try {
            TenantContext.clear();
            staffUserRepository.deleteById(staffId);
        } finally {
            restoreTenant(originalTenant);
        }
    }

    public StaffDTO getStaffByID(Long id) {
        String originalTenant = TenantContext.getCurrentTenant();
        try {
            TenantContext.clear();
            StaffUser staffUser = staffUserRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Staff not found"));
            return mapToResponseDTO(staffUser);
        } finally {
            restoreTenant(originalTenant);
        }
    }

    private StaffDTO mapToResponseDTO(StaffUser staffUser) {
        StaffDTO dto = new StaffDTO();
        dto.setId(staffUser.getId());
        dto.setName(staffUser.getName());
        dto.setUserName(staffUser.getUserName());
        dto.setRole(staffUser.getRole());
        return dto;
    }

    private void restoreTenant(String tenant) {
        if (tenant != null) {
            TenantContext.setCurrentTenant(tenant);
        } else {
            TenantContext.clear();
        }
    }
}
