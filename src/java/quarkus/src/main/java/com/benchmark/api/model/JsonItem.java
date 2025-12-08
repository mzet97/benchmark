package com.benchmark.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.UUID;

public class JsonItem {

    @JsonProperty
    public Integer id;

    @JsonProperty
    public String name;

    @JsonProperty
    public String description;

    @JsonProperty
    public String timestamp;

    @JsonProperty
    public String random;

    public JsonItem() {}

    public JsonItem(Integer id) {
        this.id = id;
        this.name = "Item " + id;
        this.description = "This is item number " + id;
        this.timestamp = java.time.Instant.now().toString();
        this.random = "data-" + UUID.randomUUID().toString();
    }

    @Override
    public String toString() {
        return "JsonItem{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", description='" + description + '\'' +
                '}';
    }
}
