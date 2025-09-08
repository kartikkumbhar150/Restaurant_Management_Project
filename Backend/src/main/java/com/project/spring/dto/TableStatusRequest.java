package com.project.spring.dto;

import lombok.Data;

@Data
public class TableStatusRequest {
    private Long tableNumber;
    private boolean isOccupied;
}
