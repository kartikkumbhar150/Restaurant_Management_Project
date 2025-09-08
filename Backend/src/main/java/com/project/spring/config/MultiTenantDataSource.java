package com.project.spring.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource;

import javax.sql.DataSource;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class MultiTenantDataSource extends AbstractRoutingDataSource {

    private final Map<Object, Object> tenantDataSources = new ConcurrentHashMap<>();

    @Autowired
    private MasterDatabaseProperties masterDbProps;

    @Override
    protected Object determineCurrentLookupKey() {
        return TenantContext.getCurrentTenant();
    }

    @Override
    protected DataSource determineTargetDataSource() {
        String tenantId = (String) determineCurrentLookupKey();

        if (tenantId == null || tenantId.isBlank()) {
            return (DataSource) getResolvedDefaultDataSource();
        }

        if (!tenantDataSources.containsKey(tenantId)) {
            DataSource dataSource = createTenantDataSource(tenantId);
            tenantDataSources.put(tenantId, dataSource);
            super.setTargetDataSources(tenantDataSources);
            super.afterPropertiesSet(); // refresh cache
        }

        return (DataSource) tenantDataSources.get(tenantId);
    }

    private DataSource createTenantDataSource(String dbName) {
        String jdbcUrl =  masterDbProps.getFirstUrl() + dbName + masterDbProps.getLastUrl() ;


        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(jdbcUrl);
        config.setUsername(masterDbProps.getUsername());
        config.setPassword(masterDbProps.getPassword());
        config.setDriverClassName("org.postgresql.Driver");
        config.setPoolName("TenantPool-" + dbName);

        return new HikariDataSource(config);
    }
}
