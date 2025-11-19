package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class InvoiceDTO {
    
    private Long tableNumber;
    private Long invoiceNumber;
    private String date;
    private String time;
    private String customerName;
    private String customerPhoneNo;
 // instead of itemDescription, quantity, pricePerItem

}