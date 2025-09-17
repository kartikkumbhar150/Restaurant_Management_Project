package com.project.spring.service.tenant;

import com.project.spring.dto.InvoiceDTO;
import com.project.spring.dto.InvoiceResponseDTO;
import com.project.spring.model.tenant.Business;
import com.project.spring.model.tenant.Invoice;
import com.project.spring.model.tenant.Order;
import com.project.spring.dto.ItemDTO;
import com.project.spring.model.tenant.OrderItem;
import com.project.spring.repo.tenant.InvoiceRepository;
import com.project.spring.repo.tenant.OrderRepository;
import com.project.spring.repo.tenant.TenantBusinessRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;
    private final TenantBusinessRepository businessRepository;
    private final OrderRepository orderRepository;
    private final SalesEmitterStore salesEmitterStore;

    @Transactional
    public InvoiceResponseDTO createInvoice(InvoiceDTO dto) {
        Long tableNumber = dto.getTableNumber();

        Order order = orderRepository.findFirstByTableNumberAndIsCompletedFalse(tableNumber)
                .orElseThrow(() -> new RuntimeException("No active order for Table: " + tableNumber));

        if (order.getInvoice() != null) {
            throw new RuntimeException("Invoice already generated for Table " + tableNumber);
        }

        Invoice invoice = new Invoice();

        // Auto invoice number
        invoice.setInvoiceNumber(generateInvoiceNumber());

        invoice.setDate(LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd")));
        invoice.setTime(LocalTime.now().format(DateTimeFormatter.ofPattern("hh:mm a")));
        invoice.setCustomerName(dto.getCustomerName());

        Business business = businessRepository.findById(1L)
                .orElseThrow(() -> new RuntimeException("Business not found"));

        invoice.setBusiness(business);
        
        int gstType = Optional.ofNullable(business.getGstType())
                .orElseThrow(() -> new RuntimeException("GST Type missing"));
        invoice.setBusinessGstType(gstType);

        invoice.setOrder(order);
        invoice.setTableNumber(order.getTableNumber());

        StringBuilder itemDesc = new StringBuilder();
        int quantity = 0;
        double subtotal = 0.0;

        for (OrderItem item : order.getItems()) {
            itemDesc.append(item.getItemName())
                    .append(" x").append(item.getQuantity()).append(", ");
            quantity += item.getQuantity();
            subtotal += item.getQuantity() * item.getPrice();
        }

        // GST Split
        double gstRate = getGstPercentageByType(gstType);
        double sgst = subtotal * (gstRate / 200.0);  // half of gstRate
        double cgst = subtotal * (gstRate / 200.0);  // half of gstRate
        double grandTotal = subtotal + sgst + cgst;

        invoice.setItemDescription(itemDesc.toString().replaceAll(", $", ""));
        invoice.setQuantity(quantity);
        invoice.setSubTotal(subtotal);
        invoice.setSgst(sgst);
        invoice.setCgst(cgst);
        invoice.setGrandTotal(grandTotal);

        // legacy fields
        invoice.setTotalAmount(grandTotal);
        invoice.setGstValue(sgst + cgst);

        Invoice savedInvoice = invoiceRepository.save(invoice);
        order.setCompleted(true);
        orderRepository.save(order);

        // Broadcast updated today's sales
        double todaySales = getTodaysSales();
        salesEmitterStore.broadcast(todaySales);

        return mapToResponseDTO(savedInvoice);
    }

    private Long generateInvoiceNumber() {
    Long lastInvoice = invoiceRepository.findLastInvoiceNumber(); // e.g. 9
    long nextNumber = (lastInvoice != null) ? lastInvoice + 1 : 1;
    return nextNumber; // stores as 1, 2, 3 ... in DB
}


    public InvoiceResponseDTO getInvoiceByInvoiceNumber(Long invoiceNumber) {
        return invoiceRepository.findByInvoiceNumber(invoiceNumber)
                .map(this::mapToResponseDTO)
                .orElse(null);
    }

    public List<InvoiceResponseDTO> getAllInvoices() {
        return invoiceRepository.findAll().stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    public double getTodaysSales() {
        String today = LocalDate.now().toString();
        return invoiceRepository.getTodaySales(today);
    }

    private InvoiceResponseDTO mapToResponseDTO(Invoice invoice) {
        InvoiceResponseDTO dto = new InvoiceResponseDTO();

        dto.setInvoiceNumber(invoice.getInvoiceNumber());
        dto.setDate(invoice.getDate());
        dto.setTime(invoice.getTime());
        dto.setCustomerName(invoice.getCustomerName());

        dto.setTotalQuantity(invoice.getQuantity());

        dto.setSubTotal(invoice.getSubTotal());
        dto.setSgst(invoice.getSgst());
        dto.setCgst(invoice.getCgst());
        int gstRate = getGstPercentageByType(invoice.getBusinessGstType());
        dto.setSgstPercent(gstRate / 2.0);
        dto.setCgstPercent(gstRate / 2.0);
        dto.setGrandTotal(invoice.getGrandTotal());

        if (invoice.getBusiness() != null) {
        dto.setBusinessName(invoice.getBusiness().getName());
        // <-- dynamic, not persisted on Invoice
        dto.setBusinessAddress(invoice.getBusiness().getAddress());
        dto.setBusinessGstNumber(invoice.getBusiness().getGstNumber());
        dto.setBusinessFssai(invoice.getBusiness().getFssaiNo());
    }

        if (invoice.getOrder() != null) {
            dto.setTableNumber(invoice.getTableNumber());

            // Convert OrderItem -> ItemDTO list
            List<ItemDTO> items = invoice.getOrder().getItems().stream()
                    .map(oi -> new ItemDTO(
                            oi.getItemName(),
                            oi.getQuantity(),
                            oi.getPrice(),
                            oi.getQuantity() * oi.getPrice()
                    ))
                    .collect(Collectors.toList());
            dto.setItems(items);
        }

        return dto;
    }

    private int getGstPercentageByType(Integer gstType) {
        return switch (gstType) {
            case 2, 3, 4, 6, 7, 9 -> 5;
            case 5, 8 -> 18;
            default -> 0;
        };
    }
}
