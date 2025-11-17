package com.project.spring.repo.tenant;

import com.project.spring.model.tenant.Business;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TenantBusinessRepository extends JpaRepository<Business, Long> {

}
