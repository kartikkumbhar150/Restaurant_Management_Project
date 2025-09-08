package com.project.spring.model.tenant;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonManagedReference; 

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "business")
public class Business {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "name")
    private String name;
    @Column(name = "logo_url")
    private String logoUrl;
    @Column(name = "gst_number")
    private String gstNumber;
    @Column(name = "fssai_no")
    private String fssaiNo;
    @Column(name = "address")
    private String address;
    @Column(name = "licence_no")
    private String licenceNo;
    @Column(name = "gst_type")
    private Integer gstType; 
    @Column(name = "phone_no")
    private String phoneNo;
    @Column(name = "email")
    private String email;
    @Column(name = "table_count")
    private Integer tableCount;

    @OneToMany(mappedBy = "business", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference("invoice-business")
    private List<Invoice> invoices;
}    
