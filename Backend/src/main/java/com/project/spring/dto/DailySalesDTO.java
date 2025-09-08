package com.project.spring.dto;

import java.time.LocalDate;

public class DailySalesDTO {
    private LocalDate date;
    private double totalSales;

    public DailySalesDTO(LocalDate date, double totalSales) {
        this.date = date;
        this.totalSales = totalSales;
    }

    // Getters & Setters
    public LocalDate getDate() {
        return date;
    }

    public void setDate(LocalDate date) {
        this.date = date;
    }

    public double getTotalSales() {
        return totalSales;
    }

    public void setTotalSales(double totalSales) {
        this.totalSales = totalSales;
    }
}
