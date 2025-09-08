package com.project.spring.service.master;

import com.project.spring.model.master.MasterBusiness;
import com.project.spring.repo.master.MasterBusinessRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class MasterBusinessService {

    @Autowired
    private MasterBusinessRepository masterBusinessRepository;

    
    //  Register a new master business
    public MasterBusiness register(MasterBusiness masterBusiness) {
        // Encrypt the password


        // Generate unique dbName using name + UUID
        String dbName = masterBusiness.getBusinessName()
                .toLowerCase()
                .replaceAll("[^a-z0-9]", "_") + "_" +
                UUID.randomUUID().toString().substring(0, 6);

        masterBusiness.setDbName(dbName);  // Set the generated dbName

        // Save the business to DB
        return masterBusinessRepository.save(masterBusiness);
    }
}
