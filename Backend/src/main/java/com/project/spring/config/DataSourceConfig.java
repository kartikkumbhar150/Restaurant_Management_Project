package com.project.spring.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.jdbc.DataSourceBuilder;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class DataSourceConfig {

    @Autowired
    private MasterDatabaseProperties masterDbProps;

    @Bean
    public DataSource dataSource() {
        MultiTenantDataSource dataSource = new MultiTenantDataSource();
        Map<Object, Object> dataSources = new HashMap<>();

        // You can preload some tenants or leave empty for dynamic registration
        dataSource.setTargetDataSources(dataSources);
        dataSource.setDefaultTargetDataSource(buildDataSource("masters_db"));
        dataSource.afterPropertiesSet();
        return dataSource;
    }

    private DataSource buildDataSource(String dbName) {
    return DataSourceBuilder.create()
            .url(masterDbProps.getJdbcUrl())
            .username(masterDbProps.getUsername())
            .password(masterDbProps.getPassword())
            .driverClassName("org.postgresql.Driver")
            .build();
}

}

