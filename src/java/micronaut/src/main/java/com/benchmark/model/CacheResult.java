package com.benchmark.model;

public class CacheResult {
    private String key;
    private String value;
    private boolean cached;

    public CacheResult() {}

    public CacheResult(String key, String value, boolean cached) {
        this.key = key;
        this.value = value;
        this.cached = cached;
    }

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }

    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public boolean isCached() {
        return cached;
    }

    public void setCached(boolean cached) {
        this.cached = cached;
    }
}
