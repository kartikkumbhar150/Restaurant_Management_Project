package com.project.spring.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.HashMap;

@Component
public class TenantDataSourceProvider {

    private final Map<String, DataSource> resolvedDataSources = new ConcurrentHashMap<>();

    @Autowired
    private MasterDatabaseProperties masterDbProps;

    public DataSource getOrCreateDataSource(String dbName) {
        return resolvedDataSources.computeIfAbsent(dbName, name -> {
            String jdbcUrl = masterDbProps.getFirstUrl() + dbName + masterDbProps.getLastUrl();

            HikariConfig config = new HikariConfig();
            config.setJdbcUrl(jdbcUrl);  
            config.setUsername(masterDbProps.getUsername());
            config.setPassword(masterDbProps.getPassword());
            config.setDriverClassName("org.postgresql.Driver");
            config.setPoolName(dbName + "-pool");

            // optional tuning
            config.setMaximumPoolSize(5);
            config.setMinimumIdle(1);

            return new HikariDataSource(config);
        });
    }

    public Map<Object, Object> getAllDataSources() {
        return new HashMap<>(resolvedDataSources);
    }
}
