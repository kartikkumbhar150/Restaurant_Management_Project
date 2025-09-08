package com.project.spring.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponse {

    private Long id;
    private boolean isCompleted;
    private Long tableNumber;
    private List<OrderItemResponse> items;
    private String itemDescription;

    
}   