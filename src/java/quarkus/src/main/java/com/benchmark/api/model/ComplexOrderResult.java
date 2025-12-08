package com.benchmark.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class ComplexOrderResult {

    @JsonProperty
    public Integer userId;

    @JsonProperty
    public String email;

    @JsonProperty
    public Long orderCount;

    @JsonProperty
    public Double totalAmount;

    @JsonProperty
    public Double avgAmount;

    @JsonProperty
    public Long daysSinceFirstOrder;

    public ComplexOrderResult() {}

    public ComplexOrderResult(Integer userId, String email, Long orderCount,
                            Double totalAmount, Double avgAmount, Long daysSinceFirstOrder) {
        this.userId = userId;
        this.email = email;
        this.orderCount = orderCount;
        this.totalAmount = totalAmount;
        this.avgAmount = avgAmount;
        this.daysSinceFirstOrder = daysSinceFirstOrder;
    }

    @Override
    public String toString() {
        return "ComplexOrderResult{" +
                "userId=" + userId +
                ", email='" + email + '\'' +
                ", orderCount=" + orderCount +
                ", totalAmount=" + totalAmount +
                ", avgAmount=" + avgAmount +
                ", daysSinceFirstOrder=" + daysSinceFirstOrder +
                '}';
    }
}
