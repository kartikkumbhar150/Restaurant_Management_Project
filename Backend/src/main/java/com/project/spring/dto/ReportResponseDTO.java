package com.project.spring.dto;

import lombok.Data;

@Data
public class ReportResponseDTO {
    private double totalSales;
    private long totalOrders;
    private long totalStaff;
    private long totalProducts;
    private double averageOrderValue;
    private String topSellingProduct;
    private long topSellingProductQuantity;
}
