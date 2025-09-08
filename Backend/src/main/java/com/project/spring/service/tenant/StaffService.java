package com.project.spring.service.tenant;

import com.project.spring.config.TenantContext;
import com.project.spring.dto.StaffDTO;
import com.project.spring.model.tenant.Staff;
import com.project.spring.repo.tenant.StaffRepository;
import com.project.spring.service.master.StaffUserService;
import com.project.spring.repo.master.MasterBusinessRepository;
import com.project.spring.model.master.MasterBusiness;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class StaffService {

    @Autowired
    private StaffRepository staffRepository;

    @Autowired
    private StaffUserService staffUserService;



    @Autowired
    private MasterBusinessRepository businessRepository;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);

    private String getCurrentTenantId() {
        String tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) throw new IllegalStateException("Tenant ID not set in context");
        return tenantId;
    }

    private Long getCurrentBusinessId() {
        String dbName = getCurrentTenantId();
        MasterBusiness business = businessRepository.findByDbName(dbName)
            .orElseThrow(() -> new RuntimeException("Business not found for DB: " + dbName));
        return business.getId();
    }

    public StaffDTO createStaff(StaffDTO dto) {
        Staff staff = new Staff();
        staff.setName(dto.getName());
        staff.setUserName(dto.getUserName());
        staff.setRole(dto.getRole());
        staff.setPassword(encoder.encode(dto.getPassword()));

        Staff saved = staffRepository.saveAndFlush(staff);

        Long businessId = getCurrentBusinessId();
        staffUserService.saveStaffToMaster(saved, businessId);
        System.out.println("Saving staff to master for: " + saved.getUserName());


        return mapToResponseDTO(saved);
    }

    public List<StaffDTO> getAllStaff() {
        return staffRepository.findAll()
                .stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    public StaffDTO updateStaff(Long id, StaffDTO dto) {
        Staff staff = staffRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Staff not found"));

        staff.setName(dto.getName());
        staff.setUserName(dto.getUserName());
        staff.setRole(dto.getRole());
        if (dto.getPassword() != null && !dto.getPassword().isEmpty()) {
            staff.setPassword(dto.getPassword());
        }

        Staff updated = staffRepository.save(staff);
        Long businessId = getCurrentBusinessId();
        staffUserService.saveStaffToMaster(updated, businessId);

        return mapToResponseDTO(updated);
    }
    public void deleteStaff(Long id) {
        Staff staff = staffRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Staff not found"));

        staffRepository.deleteById(id);
        staffUserService.deleteStaffFromMaster(staff.getId());
    }

    private StaffDTO mapToResponseDTO(Staff staff) {
        StaffDTO dto = new StaffDTO();
        dto.setId(staff.getId());
        dto.setName(staff.getName());
        dto.setUserName(staff.getUserName());
        dto.setRole(staff.getRole());
        return dto;
    }
    public StaffDTO getStaffById(Long id) {
        Staff staff = staffRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Staff not found"));
        return mapToResponseDTO(staff);
    }
    
}
