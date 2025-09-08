package com.project.spring.dto;

public class ProductResponseDTO {
    private String itemName;
    private Integer price;

    public ProductResponseDTO(String itemName, Integer price) {
        this.itemName = itemName;
        this.price = price;
    }
    // getters and setters
    public String getItemName() {
        return itemName;
    }
    public void setItemName(String itemName) {
        this.itemName = itemName;
    }    
    public Integer getPrice() {
        return price;
    }
    public void setPrice(Integer price) {
        this.price = price;
    }    
}
