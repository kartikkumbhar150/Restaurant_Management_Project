package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.TableStatusResponse;
import com.project.spring.service.tenant.TableStatusService;
import com.project.spring.repo.tenant.OrderRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
@RequestMapping("/api/v1/table-status")
public class TableStatusController {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private TableStatusService tableStatusService;

    /**
     * Normal GET for single table status
     */
    @GetMapping("/{tableNumber}")
    public ResponseEntity<TableStatusResponse> getTableStatus(@PathVariable Long tableNumber) {
        boolean isOccupied = orderRepository.existsByTableNumberAndIsCompletedFalse(tableNumber);
        TableStatusResponse response = new TableStatusResponse(tableNumber, isOccupied);
        return ResponseEntity.ok(response);
    }

    /**
     * Normal GET for all table statuses
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<TableStatusResponse>>> getAllTableStatus() {
        try {
            List<TableStatusResponse> table = tableStatusService.getAllTableStatus();
            return ResponseEntity.ok(new ApiResponse<>("success", "Fetched all table-status", table));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ApiResponse<>("failure", e.getMessage(), null));
        }
    }

    /**
     * SSE for single table live updates
     */
    @GetMapping(value = "/stream/{tableNumber}", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamTableStatus(@PathVariable Long tableNumber) {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);
        ExecutorService executor = Executors.newSingleThreadExecutor();

        executor.execute(() -> {
            try {
                while (true) {
                    boolean isOccupied = tableStatusService.isTableOccupied(tableNumber);
                    emitter.send(SseEmitter.event()
                            .name("table-status")
                            .data(new TableStatusResponse(tableNumber, isOccupied)));

                    Thread.sleep(2000); // poll every 2 sec
                }
            } catch (IOException | InterruptedException e) {
                emitter.completeWithError(e);
            }
        });

        return emitter;
    }

    /**
     * SSE for all tables live updates
     */
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamAllTableStatus() {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);
        ExecutorService executor = Executors.newSingleThreadExecutor();

        executor.execute(() -> {
            try {
                while (true) {
                    List<TableStatusResponse> allStatus = tableStatusService.getAllTableStatus();
                    emitter.send(SseEmitter.event()
                            .name("all-table-status")
                            .data(allStatus));

                    Thread.sleep(2000); // poll every 2 sec
                }
            } catch (IOException | InterruptedException e) {
                emitter.completeWithError(e);
            }
        });

        return emitter;
    }
}
