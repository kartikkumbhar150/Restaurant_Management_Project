package com.project.spring.repo.master;

import com.project.spring.model.master.MasterBusiness;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MasterBusinessRepository extends JpaRepository<MasterBusiness, Long> {

    // Fetch business by tenant database name
    Optional<MasterBusiness> findByDbName(String dbName);
}
