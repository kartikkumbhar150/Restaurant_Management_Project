package com.project.spring.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import jakarta.persistence.EntityManagerFactory;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
    basePackages = "com.project.spring.repo.tenant",
    entityManagerFactoryRef = "tenantEntityManagerFactory",
    transactionManagerRef = "tenantTransactionManager"
)
public class TenantDbConfig {

    @Autowired
    private MasterDatabaseProperties masterDbProps;
    @Bean(name = "tenantDataSource")
    public DataSource tenantDataSource() {
        Map<Object, Object> targetDataSources = new HashMap<>();
        MultiTenantDataSource dataSource = new MultiTenantDataSource();
        dataSource.setTargetDataSources(targetDataSources);
        dataSource.setDefaultTargetDataSource(defaultTenantDataSource()); // Fallback
        dataSource.afterPropertiesSet();
        return dataSource;
    }

    public DataSource defaultTenantDataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(masterDbProps.getJdbcUrl());
        config.setUsername(masterDbProps.getUsername());
        config.setPassword(masterDbProps.getPassword());
        config.setDriverClassName("org.postgresql.Driver");
        config.setPoolName("FallbackTenantPool");
        return new HikariDataSource(config);
    }

    @Bean(name = "tenantEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean tenantEntityManagerFactory(
            @Qualifier("tenantDataSource") DataSource tenantDataSource,
            EntityManagerFactoryBuilder builder) {

        return builder
                .dataSource(tenantDataSource)
                .packages("com.project.spring.model.tenant")
                .persistenceUnit("tenant")
                .build();
    }

    @Bean(name = "tenantTransactionManager")
    public PlatformTransactionManager tenantTransactionManager(
            @Qualifier("tenantEntityManagerFactory") EntityManagerFactory tenantEntityManagerFactory) {

        return new JpaTransactionManager(tenantEntityManagerFactory);
    }
}
