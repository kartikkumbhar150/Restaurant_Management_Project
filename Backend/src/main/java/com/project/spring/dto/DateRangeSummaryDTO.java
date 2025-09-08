package com.project.spring.dto;

import lombok.Data;
import java.time.LocalDate;
import java.util.List;

@Data
public class DateRangeSummaryDTO {
    private LocalDate startDate;
    private LocalDate endDate;
    private double totalSales;
    private long invoiceCount;
    private double averageInvoiceValue;
    private List<ItemReportDTO> mostSellingItems;
}
