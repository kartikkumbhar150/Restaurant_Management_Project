package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.InvoiceDTO;
import com.project.spring.dto.InvoiceResponseDTO;
import com.project.spring.service.tenant.InvoiceService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/invoices")
@RequiredArgsConstructor
public class InvoiceController {

    private final InvoiceService invoiceService;

    @PostMapping
    public ResponseEntity<ApiResponse<InvoiceResponseDTO>> createInvoice(@RequestBody InvoiceDTO dto) {
        try {
            InvoiceResponseDTO invoice = invoiceService.createInvoice(dto);
            return ResponseEntity.ok(
                new ApiResponse<>("success", "Invoice created successfully", invoice)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to create invoice: " + e.getMessage(), null)
            );
        }
    }

    @GetMapping("/{invoiceNumber}")
public ResponseEntity<ApiResponse<InvoiceResponseDTO>> getInvoiceByInvoiceNumber(
        @PathVariable Long invoiceNumber) {
    try {
        InvoiceResponseDTO invoice = invoiceService.getInvoiceByInvoiceNumber(invoiceNumber);
        if (invoice != null) {
            return ResponseEntity.ok(
                new ApiResponse<>("success", "Invoice found", invoice)
            );
        } else {
            return ResponseEntity.status(404).body(
                new ApiResponse<>("failure", "Invoice not found", null)
            );
        }
    } catch (Exception e) {
        return ResponseEntity.status(500).body(
            new ApiResponse<>("failure", "Error retrieving invoice: " + e.getMessage(), null)
        );
    }
}


    @GetMapping
    public ResponseEntity<ApiResponse<List<InvoiceResponseDTO>>> getAllInvoices() {
        try {
            List<InvoiceResponseDTO> invoices = invoiceService.getAllInvoices();
            return ResponseEntity.ok(
                new ApiResponse<>("success", "All invoices fetched", invoices)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to fetch invoices: " + e.getMessage(), null)
            );
        }
    }
}
