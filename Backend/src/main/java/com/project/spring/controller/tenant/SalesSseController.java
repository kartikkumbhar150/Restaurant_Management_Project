package com.project.spring.controller.tenant;

import com.project.spring.service.tenant.SalesEmitterStore;
import lombok.RequiredArgsConstructor;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api/v1/sales")
@RequiredArgsConstructor
public class SalesSseController {

    private final SalesEmitterStore salesEmitterStore;

    @GetMapping(value = "/live", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter subscribeToSales() {
        return salesEmitterStore.subscribe();
    }

    @GetMapping("/today")
    public ResponseEntity<String> getTodaySales() {
        String total = salesEmitterStore.getTotal();
        return ResponseEntity.ok(total);
    }

}
