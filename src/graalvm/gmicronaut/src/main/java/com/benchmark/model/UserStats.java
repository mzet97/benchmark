package com.benchmark.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class UserStats {
    @JsonProperty("userId")
    private Integer userId;

    @JsonProperty("userName")
    private String userName;

    @JsonProperty("totalOrders")
    private Integer totalOrders;

    @JsonProperty("totalValue")
    private Double totalValue;

    @JsonProperty("averageOrderValue")
    private Double averageOrderValue;

    public UserStats() {}

    public UserStats(Integer userId, String userName, Integer totalOrders, Double totalValue, Double averageOrderValue) {
        this.userId = userId;
        this.userName = userName;
        this.totalOrders = totalOrders;
        this.totalValue = totalValue;
        this.averageOrderValue = averageOrderValue;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public Integer getTotalOrders() {
        return totalOrders;
    }

    public void setTotalOrders(Integer totalOrders) {
        this.totalOrders = totalOrders;
    }

    public Double getTotalValue() {
        return totalValue;
    }

    public void setTotalValue(Double totalValue) {
        this.totalValue = totalValue;
    }

    public Double getAverageOrderValue() {
        return averageOrderValue;
    }

    public void setAverageOrderValue(Double averageOrderValue) {
        this.averageOrderValue = averageOrderValue;
    }
}
