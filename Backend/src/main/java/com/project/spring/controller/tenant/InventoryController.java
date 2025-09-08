package com.project.spring.controller.tenant;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.project.spring.dto.ApiResponse;
import com.project.spring.dto.InventoryDTO;
import com.project.spring.model.tenant.Inventory;
import com.project.spring.service.tenant.InventoryService;

import java.util.List;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    @PostMapping("/add")
    public ResponseEntity<ApiResponse<Inventory>> createInventory(@RequestBody InventoryDTO inventory) {
        try {
            Inventory createdInventory = inventoryService.createInventory(inventory);
            ApiResponse<Inventory> response = new ApiResponse<>("success", "Inventory created successfully", createdInventory);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            ApiResponse<Inventory> errorResponse = new ApiResponse<>("failure", "Failed to create inventory: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @PostMapping("/add-bulk")
    public ResponseEntity<ApiResponse<List<Inventory>>> createInventory(@RequestBody List<InventoryDTO> inventoryDTOList) {
        try {
            List<Inventory> createdInventories = inventoryService.createInventory(inventoryDTOList);
            ApiResponse<List<Inventory>> response = new ApiResponse<>("success", "Bulk inventory created successfully", createdInventories);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            ApiResponse<List<Inventory>> errorResponse = new ApiResponse<>("failure", "Failed to create bulk inventory: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Inventory>>> getAllInventory() {
        try {
            List<Inventory> inventories = inventoryService.getAllInventory();
            ApiResponse<List<Inventory>> response = new ApiResponse<>("success", "Fetched all inventory", inventories);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            ApiResponse<List<Inventory>> errorResponse = new ApiResponse<>("failure", "Failed to fetch inventory: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}
