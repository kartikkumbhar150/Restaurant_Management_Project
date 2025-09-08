package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class KotItemDTO {
    private Long orderId;
    private String itemName;
    private int quantity;
    private Long tableNumber;
    private boolean completed;
}
