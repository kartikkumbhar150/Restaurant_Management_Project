package com.project.spring.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "spring.datasource.master")
@Getter
@Setter
public class MasterDatabaseProperties {
    private String jdbcUrl;        // matches spring.datasource.master.jdbc-url
    private String username;
    private String password;
    private String firstUrl;  
    private String lastUrl;   
}
