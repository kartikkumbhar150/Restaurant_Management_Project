package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TimeSlotReportDTO {
    private String timeSlot;
    private int invoiceCount;
}
