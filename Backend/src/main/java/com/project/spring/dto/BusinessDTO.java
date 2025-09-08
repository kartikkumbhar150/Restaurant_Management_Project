package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BusinessDTO {
    private Long id;
    private String name;
    private String gstNumber;
    private String address;
    private String logoUrl;
    private String fssaiNo;
    private String licenceNo;
    private Integer gstType;
    private String phoneNo;
    private String email;
    private Integer tableCount;
}
