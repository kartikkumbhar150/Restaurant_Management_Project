// CategoryItemReportDTO.java
package com.project.spring.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CategoryItemReportDTO {
    private String category;
    private String itemName;
    private Long quantity;
}
