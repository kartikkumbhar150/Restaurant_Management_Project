package com.project.spring.service.tenant;

import com.project.spring.dto.DailySalesDTO;
import com.project.spring.dto.DateRangeSummaryDTO;
import com.project.spring.dto.DateRangeExpenseDTO;
import com.project.spring.dto.ItemReportDTO;
import com.project.spring.repo.tenant.InvoiceRepository;
import com.project.spring.repo.tenant.InventoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final InvoiceRepository invoiceRepository;
    private final InventoryRepository inventoryRepository;


    
    public DateRangeSummaryDTO buildSummary(LocalDate start, LocalDate end) {
        String startStr = start.toString();
        String endStr = end.toString();

        double total = invoiceRepository.getSalesBetweenDates(startStr, endStr);
        long count = invoiceRepository.countInvoicesBetweenDates(startStr, endStr);
        double q = inventoryRepository.getTotalExpenseBetweenDates(startStr, endStr);

        // Fetch only top 5 directly from DB
        List<ItemReportDTO> topItems = invoiceRepository.getMostSellingItems(PageRequest.of(0, 5));

        DateRangeSummaryDTO dto = new DateRangeSummaryDTO();
        dto.setStartDate(start);
        dto.setEndDate(end);
        dto.setTotalSales(total);
        dto.setInvoiceCount(count);
        dto.setExpense(q);
        dto.setAverageInvoiceValue(count > 0 ? total / count : 0);
        dto.setMostSellingItems(topItems);

        return dto;
    }
    public DateRangeExpenseDTO expenseSummary(LocalDate start, LocalDate end){
    String startStr = start.toString();  // "2025-09-01"
    String endStr = end.toString();      // "2025-09-22"

    double qs = inventoryRepository.getTotalExpenseBetweenDates(startStr, endStr);

    DateRangeExpenseDTO dto = new DateRangeExpenseDTO();
    dto.setExpense(qs);
    return dto;
}




    public List<DailySalesDTO> getLast7DaysSales() {
        List<Object[]> results = invoiceRepository.getLast7DaysSalesWithZeros();
        List<DailySalesDTO> salesList = new ArrayList<>();

        for (Object[] row : results) {
            LocalDate date = ((java.sql.Date) row[0]).toLocalDate();
            double total = ((Number) row[1]).doubleValue();
            salesList.add(new DailySalesDTO(date, total));
        }

        return salesList;
    }
    public List<Map<String, Object>> getLast7DaysSalesByTimeSlots() {
    List<Object[]> rows = invoiceRepository.getLast7DaysSalesByTimeSlots();
    List<Map<String, Object>> result = new ArrayList<>();

    for (Object[] row : rows) {
        Map<String, Object> map = new HashMap<>();
        map.put("timeSlot", (String) row[0]);
        map.put("totalSales", ((Number) row[1]).doubleValue());
        result.add(map);
    }

    return result;
}

}
