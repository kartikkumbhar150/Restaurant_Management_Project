package com.project.spring.repo.master;

import com.project.spring.model.master.MasterBusiness;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MasterBusinessRepository extends JpaRepository<MasterBusiness, Long> {
    Optional<MasterBusiness> findByDbName(String dbName); // <-- Add this method
}
