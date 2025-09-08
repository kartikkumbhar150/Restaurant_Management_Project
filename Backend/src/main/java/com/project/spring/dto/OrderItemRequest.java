package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor

public class OrderItemRequest {
    private Long id;
    private int quantity;
    private Long productId;
    private Long tableNumber;

}