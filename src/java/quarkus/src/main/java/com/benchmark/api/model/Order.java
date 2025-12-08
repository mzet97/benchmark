package com.benchmark.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public class Order {

    @JsonProperty
    public Integer id;

    @JsonProperty
    public Integer userId;

    @JsonProperty
    public Double totalAmount;

    @JsonProperty
    public String status;

    @JsonProperty
    public String createdAt;

    @JsonProperty
    public List<OrderItem> items;

    @JsonProperty
    public User user;

    public Order() {}

    public Order(Integer id, Integer userId, Double totalAmount, String status, String createdAt) {
        this.id = id;
        this.userId = userId;
        this.totalAmount = totalAmount;
        this.status = status;
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Order{" +
                "id=" + id +
                ", userId=" + userId +
                ", totalAmount=" + totalAmount +
                ", status='" + status + '\'' +
                ", createdAt='" + createdAt + '\'' +
                '}';
    }
}
