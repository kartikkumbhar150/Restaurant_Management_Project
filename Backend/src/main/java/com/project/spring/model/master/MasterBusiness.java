package com.project.spring.model.master;


import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor

@Entity
@Table(name = "businesses")
public class MasterBusiness {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "business_name")
    private String businessName;
    @Column(name = "owner_name")
    private String ownerName;
    @Column(name = "\"db_name\"") // with quotes
    private String dbName;
    @Column(name = "phone_no")
    private Long phoneNo;  
    @Column(name = "email")
    private String email;  
    @Column(name = "logo_url")
    private String logoUrl;

   

}

