package com.project.spring.service.tenant;

import com.project.spring.dto.OrderItemRequest;
import com.project.spring.dto.OrderItemResponse;
import com.project.spring.dto.OrderRequest;
import com.project.spring.dto.OrderResponse;
import com.project.spring.exception.ResourceNotFoundException;
import com.project.spring.model.tenant.Order;
import com.project.spring.model.tenant.OrderItem;
import com.project.spring.model.tenant.Product;
import com.project.spring.repo.tenant.OrderRepository;
import com.project.spring.repo.tenant.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import jakarta.transaction.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final KotStore kotStore; // Inject KotStore for KOT broadcasting

    /**
     * Creates a new order if table is not already occupied.
     */
    @Transactional
    public OrderResponse createOrder(OrderRequest request) {
        Long tableNumber = request.getTableNumber();

        // Check if table already has an active (incomplete) order
        boolean isTableOccupied = orderRepository.existsByTableNumberAndIsCompletedFalse(tableNumber);
        if (isTableOccupied) {
            throw new RuntimeException("Table " + tableNumber +
                    " is already occupied. Please complete the existing order first.");
        }

        Order order = new Order();
        order.setTableNumber(tableNumber);
        order.setCompleted(false);

        List<OrderItem> orderItems = new ArrayList<>();

        for (OrderItemRequest itemRequest : request.getItems()) {
            Product product = productRepository.findById(itemRequest.getProductId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Product not found: " + itemRequest.getProductId()));

            OrderItem orderItem = new OrderItem();
            orderItem.setProductId(product.getId());
            orderItem.setProduct(product);
            orderItem.setItemName(product.getName());
            orderItem.setPrice(product.getPrice());
            orderItem.setQuantity(itemRequest.getQuantity());
            orderItem.setOrder(order);

            orderItems.add(orderItem);
        }

        order.setItems(orderItems);
        Order savedOrder = orderRepository.save(order);

        kotStore.addOrder(savedOrder); // Send to KOT

        return mapToOrderResponse(savedOrder);
    }

    /**
     * Fetch order by ID with items to avoid LazyInitializationException.
     */
    @Transactional
    public OrderResponse getOrderById(Long tableNumber) {
        Order order = orderRepository.findByIdWithItems(tableNumber)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Order not found with ID: " + tableNumber));
        return mapToOrderResponse(order);
    }

    /**
     * Update an existing order with new or additional items.
     */
    @Transactional
    public OrderResponse updateOrder(Long orderId, OrderRequest request) {
        Order existingOrder = orderRepository.findByIdWithItems(orderId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Order not found with ID: " + orderId));

        existingOrder.setTableNumber(request.getTableNumber());

        for (OrderItemRequest itemRequest : request.getItems()) {
            Optional<OrderItem> existingItemOpt = existingOrder.getItems().stream()
                    .filter(item -> item.getProductId() != null &&
                            item.getProductId().equals(itemRequest.getProductId()))
                    .findFirst();

            if (existingItemOpt.isPresent()) {
                OrderItem existingItem = existingItemOpt.get();
                existingItem.setQuantity(existingItem.getQuantity() + itemRequest.getQuantity());
            } else {
                Product product = productRepository.findById(itemRequest.getProductId())
                        .orElseThrow(() -> new ResourceNotFoundException(
                                "Product not found with ID: " + itemRequest.getProductId()));

                OrderItem newItem = new OrderItem();
                newItem.setProductId(product.getId());
                newItem.setProduct(product);
                newItem.setItemName(product.getName());
                newItem.setPrice(product.getPrice());
                newItem.setQuantity(itemRequest.getQuantity());
                newItem.setOrder(existingOrder);

                existingOrder.getItems().add(newItem);
            }
        }

        Order updatedOrder = orderRepository.save(existingOrder);

        kotStore.addOrder(updatedOrder); // Send updated items to KOT

        return mapToOrderResponse(updatedOrder);
    }

    /**
     * Maps an Order entity to an OrderResponse DTO.
     * Assumes items are already fetched (JOIN FETCH).
     */
    private OrderResponse mapToOrderResponse(Order order) {
        OrderResponse response = new OrderResponse();
        response.setId(order.getId());
        response.setTableNumber(order.getTableNumber());
        response.setCompleted(order.isCompleted());

        List<OrderItemResponse> itemResponses = new ArrayList<>();
        Map<String, Integer> itemCountMap = new LinkedHashMap<>();

        for (OrderItem item : order.getItems()) {
            OrderItemResponse itemResponse = new OrderItemResponse();

            Long productId = item.getProductId();
            if (productId == null && item.getProduct() != null) {
                productId = item.getProduct().getId();
            }

            itemResponse.setProductId(productId);
            itemResponse.setItemName(item.getItemName());
            itemResponse.setPrice(item.getPrice());
            itemResponse.setQuantity(item.getQuantity());

            itemResponses.add(itemResponse);

            itemCountMap.put(
                item.getItemName(),
                itemCountMap.getOrDefault(item.getItemName(), 0) + item.getQuantity()
            );
        }

        response.setItems(itemResponses);

        String itemDescription = itemCountMap.entrySet().stream()
                .map(e -> e.getKey() + " x" + e.getValue())
                .collect(Collectors.joining(", "));
        response.setItemDescription(itemDescription);

        return response;
    }
}
