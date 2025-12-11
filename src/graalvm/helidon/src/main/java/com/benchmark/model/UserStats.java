package com.benchmark.model;

public class UserStats {
    private Integer userId;
    private String userName;
    private Integer totalOrders;
    private Double totalValue;
    private Double averageValue;

    public UserStats() {}

    public UserStats(Integer userId, String userName, Integer totalOrders, Double totalValue, Double averageValue) {
        this.userId = userId;
        this.userName = userName;
        this.totalOrders = totalOrders;
        this.totalValue = totalValue;
        this.averageValue = averageValue;
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

    public Double getAverageValue() {
        return averageValue;
    }

    public void setAverageValue(Double averageValue) {
        this.averageValue = averageValue;
    }
}
