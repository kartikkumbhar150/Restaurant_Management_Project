package com.project.spring.service.tenant;

import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import com.project.spring.dto.TableStatusResponse;
import com.project.spring.repo.tenant.BusinessRepository;
import com.project.spring.repo.tenant.OrderRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TableStatusService {

    private final OrderRepository orderRepository;
    private final BusinessRepository businessRepository;

    /**
     * Check if a table is currently occupied
     */
    public boolean isTableOccupied(Long tableNumber) {
        return orderRepository.existsByTableNumberAndIsCompletedFalse(tableNumber);
    }

    /**
     * Get status for all tables
     */
    public List<TableStatusResponse> getAllTableStatus() {
        Long tableCount = businessRepository.findTableCount();
        if (tableCount == null) {
            throw new RuntimeException("Table count not found");
        }

        List<TableStatusResponse> tableStatusList = new ArrayList<>();
        for (long i = 1; i <= tableCount; i++) {
            boolean isOccupied = isTableOccupied(i);
            tableStatusList.add(new TableStatusResponse(i, isOccupied));
        }
        return tableStatusList;
    }
}
