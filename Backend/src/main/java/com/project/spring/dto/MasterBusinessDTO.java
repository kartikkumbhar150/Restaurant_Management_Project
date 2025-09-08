package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MasterBusinessDTO {
    private String businessName;
    private String ownerName;
    private String dbName;
    private Long phoneNo;
    private String email;
    private String userName;
    private String password;
    private Long userPhoneNo; 

}
