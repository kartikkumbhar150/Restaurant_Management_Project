package com.project.spring.service.tenant;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.project.spring.dto.InventoryDTO;
import com.project.spring.model.tenant.Inventory;
import com.project.spring.repo.tenant.InventoryRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class InventoryService {

    @Autowired
    private InventoryRepository inventoryRepository;

    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("hh:mm a");


    /** Create single inventory item (auto-sets today's date & time). */
    public Inventory createInventory(InventoryDTO inventoryDTO) {
        Inventory inventory = new Inventory();
        inventory.setItemName(inventoryDTO.getItemName());
        inventory.setQuantity(inventoryDTO.getQuantity());
        inventory.setUnit(inventoryDTO.getUnit());
        inventory.setPrice(inventoryDTO.getPrice());

        // auto-stamp
        inventory.setDate(LocalDate.now().toString());                 // e.g. 2025-09-05
        inventory.setTime(LocalTime.now().format(TIME_FORMAT));        // e.g. 16:42

        return inventoryRepository.save(inventory);
    }

    /** Bulk create inventory items (each auto-stamped). */
    public List<Inventory> createInventory(List<InventoryDTO> inventoryDTOList) {
        List<Inventory> inventoryList = inventoryDTOList.stream().map(dto -> {
            Inventory inventory = new Inventory();
            inventory.setItemName(dto.getItemName());
            inventory.setQuantity(dto.getQuantity());
            inventory.setUnit(dto.getUnit());
            inventory.setPrice(dto.getPrice());

            inventory.setDate(LocalDate.now().toString());
            inventory.setTime(LocalTime.now().format(TIME_FORMAT));

            return inventory;
        }).collect(Collectors.toList());

        return inventoryRepository.saveAll(inventoryList);
    }

    /** Fetch all inventory records. */
    public List<Inventory> getAllInventory() {
        return inventoryRepository.findAll();
    }
}
