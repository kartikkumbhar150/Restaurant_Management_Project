package com.project.spring.controller.tenant;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.OrderRequest;
import com.project.spring.dto.OrderResponse;
import com.project.spring.service.tenant.OrderService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    // Create an order
    @PostMapping
    public ResponseEntity<ApiResponse<OrderResponse>> createOrder(@RequestBody OrderRequest orderRequest) {
        try {
            OrderResponse createdOrder = orderService.createOrder(orderRequest);
            return ResponseEntity.ok(
                new ApiResponse<>("success", "Order created successfully", createdOrder)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to create order: " + e.getMessage(), null)
            );
        }
    }

    // Get an order by ID
    @GetMapping("/{tableNumber}")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrderById(@PathVariable Long tableNumber) {
        try {
            OrderResponse orderResponse = orderService.getOrderById(tableNumber);
            if (orderResponse != null) {
                return ResponseEntity.ok(
                    new ApiResponse<>("success", "Order fetched successfully", orderResponse)
                );
            } else {
                return ResponseEntity.status(404).body(
                    new ApiResponse<>("failure", "Order not found", null)
                );
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Error fetching order: " + e.getMessage(), null)
            );
        }
    }

    // Update an order by ID
    @PutMapping("/{orderId}")
    public ResponseEntity<ApiResponse<OrderResponse>> updateOrder(
            @PathVariable Long orderId,
            @RequestBody OrderRequest orderRequest) {
        try {
            OrderResponse updatedOrder = orderService.updateOrder(orderId, orderRequest);
            if (updatedOrder != null) {
                return ResponseEntity.ok(
                    new ApiResponse<>("success", "Order updated successfully", updatedOrder)
                );
            } else {
                return ResponseEntity.status(404).body(
                    new ApiResponse<>("failure", "Order not found", null)
                );
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to update order: " + e.getMessage(), null)
            );
        }
    }

    // Delete an order by ID
    @DeleteMapping("/{orderId}")
    public ResponseEntity<ApiResponse<Void>> deleteOrder(@PathVariable Long orderId) {
        try {
            boolean deleted = orderService.deleteOrder(orderId);
            if (deleted) {
                return ResponseEntity.ok(
                    new ApiResponse<>("success", "Order deleted successfully", null)
                );
            } else {
                return ResponseEntity.status(404).body(
                    new ApiResponse<>("failure", "Order not found", null)
                );
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ApiResponse<>("failure", "Failed to delete order: " + e.getMessage(), null)
            );
        }
    }
}
