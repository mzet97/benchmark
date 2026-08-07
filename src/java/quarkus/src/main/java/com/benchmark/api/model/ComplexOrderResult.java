package com.benchmark.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;

// Mirrors UserOrderStats in contracts/grpc/benchmark.proto. Wire names are
// camelCase, matching the proto3 JSON mapping of the snake_case proto fields.
// See contracts/rest/canonical-payloads.md.
public class ComplexOrderResult {

    @JsonProperty
    public Integer userId;

    @JsonProperty
    public String userName;

    @JsonProperty
    public Long totalOrders;

    @JsonProperty
    public Double totalValue;

    @JsonProperty
    public Double averageOrderValue;

    public ComplexOrderResult() {}

    public ComplexOrderResult(Integer userId, String userName, Long totalOrders,
                            Double totalValue, Double averageOrderValue) {
        this.userId = userId;
        this.userName = userName;
        this.totalOrders = totalOrders;
        this.totalValue = totalValue;
        this.averageOrderValue = averageOrderValue;
    }

    @Override
    public String toString() {
        return "ComplexOrderResult{" +
                "userId=" + userId +
                ", userName='" + userName + '\'' +
                ", totalOrders=" + totalOrders +
                ", totalValue=" + totalValue +
                ", averageOrderValue=" + averageOrderValue +
                '}';
    }
}
