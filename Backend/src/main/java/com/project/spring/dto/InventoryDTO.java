package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor

public class InventoryDTO {
    private Long id;
    private String itemName;
    private int quantity;
    private String unit; 
    private double price;
    private String date;
    private String time;
}
