package com.benchmark.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class OrderItem {

    @JsonProperty
    public Integer id;

    @JsonProperty
    public Integer orderId;

    @JsonProperty
    public String productName;

    @JsonProperty
    public Integer quantity;

    @JsonProperty
    public Double price;

    public OrderItem() {}

    public OrderItem(Integer id, Integer orderId, String productName, Integer quantity, Double price) {
        this.id = id;
        this.orderId = orderId;
        this.productName = productName;
        this.quantity = quantity;
        this.price = price;
    }

    @Override
    public String toString() {
        return "OrderItem{" +
                "id=" + id +
                ", orderId=" + orderId +
                ", productName='" + productName + '\'' +
                ", quantity=" + quantity +
                ", price=" + price +
                '}';
    }
}
