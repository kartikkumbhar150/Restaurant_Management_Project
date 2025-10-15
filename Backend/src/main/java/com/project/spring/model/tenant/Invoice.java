package com.project.spring.model.tenant;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import com.fasterxml.jackson.annotation.JsonBackReference;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "invoice")
public class Invoice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "invoice_number")
    private Long invoiceNumber;

    private String date;
    private String time;

    @Column(name = "customer_name")
    private String customerName;

    @Column(name = "customer_phoneNo")
    private String customerPhoneNo;
    @Column(name = "item_description")
    private String itemDescription;

    @Column(name = "quantity")
    private int quantity;

    @Column(name = "sub_total")
    private double subTotal;

    @Column(name = "sgst")
    private double sgst;

    @Column(name = "cgst")
    private double cgst;

    @Column(name = "grand_total")
    private double grandTotal;

    @Column(name = "total_amount") // keep for compatibility
    private double totalAmount;

    

    @Column(name = "table_number")
    private Long tableNumber;

    @Column(name = "business_gst_type")
    private Integer businessGstType;

    @Column(name = "gst_value")
    private double gstValue;

    @ManyToOne
    @JoinColumn(name = "business_id")
    @JsonBackReference("invoice-business")
    private Business business;

    @OneToOne
    @JoinColumn(name = "order_id")
    private Order order;
}
