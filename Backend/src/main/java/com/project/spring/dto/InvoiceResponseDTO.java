package com.project.spring.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class InvoiceResponseDTO {

    private Long invoiceNumber;
    private String date;
    private String time;
    private String customerName;
    private String customerPhoneNo;

    private List<ItemDTO> items;
    private int totalQuantity;

    private double subTotal;
    private double sgst;
    private double cgst;
    private double sgstPercent;
    private double cgstPercent;

    private double grandTotal;
    
    private String logoUrl;
    private String businessName;
    private String businessAddress;
    private String businessGstNumber;
    private String businessFssai;
    private Long tableNumber;
}
