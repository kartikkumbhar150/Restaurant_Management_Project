package com.project.spring.service.master;

import com.project.spring.model.master.MasterBusiness;
import com.project.spring.repo.master.MasterBusinessRepository;
import com.project.spring.repo.master.StaffUserRepository;
import com.project.spring.model.master.StaffUser;
import com.project.spring.config.MasterDatabaseProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.util.Optional;
import java.util.UUID;

@Service
public class BusinessProvisionService {

    @Autowired
    private MasterBusinessRepository masterRepo;

    @Autowired
    private StaffUserRepository staffUserRepo;

    @Autowired
    private MasterDatabaseProperties masterDbProps;



    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder(12);

    public String createBusiness(String name, String password, String dbNamee, String ownerName, String userName,  Long phoneNo , String email) {
        // Check for duplicate username
        Optional<MasterBusiness> existing = masterRepo.findByDbName(dbNamee);
        if (existing.isPresent()) {
            throw new RuntimeException("Username already exists");
        }

        // Generate database name
        String baseName = name.trim().toLowerCase().replaceAll("[^a-z0-9]", "_");
        String dbName = "business_" + baseName + "_" + UUID.randomUUID().toString().substring(0, 3);

        // Step 1: Create DB first to prevent saving entry if DB fails
        createDatabase(dbName);
        initializeSchema(dbName);

        // Step 2: Save business credentials in master DB
        MasterBusiness business = new MasterBusiness();
        business.setBusinessName(name);
        business.setOwnerName(ownerName);
        business.setDbName(dbName);
        business.setPhoneNo(phoneNo);
        business.setEmail(email);

        masterRepo.save(business);

        StaffUser staffUser = new StaffUser();
        staffUser.setName(ownerName);
        staffUser.setUserName(userName);
        staffUser.setPassword(passwordEncoder.encode(password));
        staffUser.setDbName(dbName);
        staffUser.setRole("ADMIN");
       

        staffUserRepo.save(staffUser);

        return dbName;
    }

    private void createDatabase(String dbName) {
        String masterDbUrl = masterDbProps.getJdbcUrl(); 
        String dbUsername = masterDbProps.getUsername();
        String dbPassword = masterDbProps.getPassword();

        try (Connection conn = DriverManager.getConnection(masterDbUrl, dbUsername, dbPassword)) {
            Statement stmt = conn.createStatement();
            stmt.executeUpdate("CREATE DATABASE \"" + dbName + "\"");
            System.out.println(" Created database: " + dbName);
        } catch (Exception e) {
            throw new RuntimeException(" DB creation failed: " + e.getMessage(), e);
        }
    }

    private void initializeSchema(String dbName) {
        String tenantDbUrl = masterDbProps.getFirstUrl() + dbName + masterDbProps.getLastUrl();
        String dbUsername = masterDbProps.getUsername();
        String dbPassword = masterDbProps.getPassword();

        try (Connection conn = DriverManager.getConnection(tenantDbUrl, dbUsername, dbPassword)) {
            Statement stmt = conn.createStatement();

            stmt.executeUpdate("""
CREATE TABLE business (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    gst_number VARCHAR(20) UNIQUE,
    fssai_no VARCHAR(20) UNIQUE,
    address VARCHAR(200) NOT NULL,
    logo_url VARCHAR(200),
    gst_type INTEGER,
    licence_no VARCHAR(200) UNIQUE,
    phone_no VARCHAR(20),
    email VARCHAR(100),
    table_count INTEGER
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    image_url VARCHAR(200),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(200),
    category VARCHAR(100),
    subCategory VARCHAR(100),
    price INTEGER
);

CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    is_completed BOOLEAN,
    table_number BIGINT
);

CREATE TABLE order_item (
    id SERIAL PRIMARY KEY,
    item_name VARCHAR(255),
    price INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    order_id BIGINT,
    product_id BIGINT,
    CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE invoice (
    id SERIAL PRIMARY KEY,
    
    customer_name VARCHAR(255),
    date VARCHAR(255),
    invoice_number BIGINT,
    item_description VARCHAR(255),
    payment_status VARCHAR(255),
    quantity INTEGER NOT NULL,
    sub_total DOUBLE PRECISION NOT NULL DEFAULT 0,
    sgst DOUBLE PRECISION NOT NULL DEFAULT 0,
    cgst DOUBLE PRECISION NOT NULL DEFAULT 0,
    grand_total DOUBLE PRECISION NOT NULL DEFAULT 0,

    total_amount DOUBLE PRECISION NOT NULL,
    gst_value DOUBLE PRECISION,

    business_id BIGINT,
    "time" VARCHAR(255),
    table_number BIGINT,
    order_id BIGINT
);


CREATE TABLE staff (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    password VARCHAR(255) NOT NULL,
    role VARCHAR(255),
    username VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE inventory (
    id SERIAL PRIMARY KEY,
    item_name VARCHAR(255),
    quantity INTEGER,
    unit VARCHAR(255),
    price BIGINT,
    date VARCHAR(255),
    time VARCHAR(255)
);



""");



            System.out.println("Initialized schema in DB: " + dbName);
        } catch (Exception e) {
            throw new RuntimeException(" Schema initialization failed in DB [" + dbName + "]: " + e.getMessage(), e);
        }
    }
}
