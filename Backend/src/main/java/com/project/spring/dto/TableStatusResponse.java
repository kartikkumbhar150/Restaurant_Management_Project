package com.project.spring.dto;

import lombok.Data;

@Data
public class TableStatusResponse {
    
    private Long tableNumber;
    private boolean isOccupied;
    public TableStatusResponse(Long tableNumber, boolean isOccupied) {
       this.tableNumber = tableNumber;
       this.isOccupied = isOccupied;
    }
}
