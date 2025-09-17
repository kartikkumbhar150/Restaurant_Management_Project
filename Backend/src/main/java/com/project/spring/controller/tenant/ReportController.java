package com.project.spring.controller.tenant;

import com.project.spring.dto.DailySalesDTO;
import com.project.spring.dto.DateRangeRequest;
import com.project.spring.dto.DateRangeSummaryDTO;
import com.project.spring.model.tenant.Invoice;
import com.project.spring.repo.tenant.InvoiceRepository;
import com.project.spring.service.tenant.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/report")
@CrossOrigin("*")
@RequiredArgsConstructor
public class ReportController {

    private final InvoiceRepository invoiceRepository;
    private final ReportService dateRangeReportService;
    

    @GetMapping("/most-selling-items")
    public ResponseEntity<?> getMostSellingItems() {
        // ✅ Fetch only top 5 items
        return ResponseEntity.ok(invoiceRepository.getMostSellingItems(PageRequest.of(0, 5)));
    }

    @GetMapping("/last-invoice-number")
    public ResponseEntity<?> getLastInvoiceNumber() {
        return ResponseEntity.ok(Map.of("lastInvoiceNumber", invoiceRepository.findLastInvoiceNumber()));
    }

    @PostMapping("/invoices-between")
    public ResponseEntity<?> getInvoicesBetween(@RequestBody DateRangeRequest range) {
        String startStr = range.getStartDate().toString();
        String endStr = range.getEndDate().toString();

        List<Invoice> invoices = invoiceRepository.findInvoicesBetweenDates(startStr, endStr);
        return ResponseEntity.ok(invoices);
    }

    @PostMapping("/summary-range")
    public ResponseEntity<?> getSummaryForDateRange(@RequestBody DateRangeRequest range) {
        DateRangeSummaryDTO summary = dateRangeReportService.buildSummary(range.getStartDate(), range.getEndDate());
        return ResponseEntity.ok(summary);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleError(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("success", false, "error", ex.getMessage()));
    }
    @GetMapping("/last7days-sales")
    public List<DailySalesDTO> getLast7DaysSales() {
        return dateRangeReportService.getLast7DaysSales();
    }

    @GetMapping("/last7days-timeslots")
    public List<Map<String, Object>> getLast7DaysTimeSlotSales() {
        return dateRangeReportService.getLast7DaysSalesByTimeSlots();
    }

}
