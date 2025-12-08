package com.benchmark.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class User {

    @JsonProperty
    public Integer id;

    @JsonProperty
    public String email;

    @JsonProperty
    public String firstName;

    @JsonProperty
    public String lastName;

    @JsonProperty
    public Integer age;

    @JsonProperty
    public String createdAt;

    public User() {}

    public User(Integer id, String email, String firstName, String lastName, Integer age, String createdAt) {
        this.id = id;
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
        this.age = age;
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", email='" + email + '\'' +
                ", firstName='" + firstName + '\'' +
                ", lastName='" + lastName + '\'' +
                ", age=" + age +
                ", createdAt='" + createdAt + '\'' +
                '}';
    }
}
