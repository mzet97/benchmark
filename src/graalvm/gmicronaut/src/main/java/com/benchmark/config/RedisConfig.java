package com.benchmark.config;

import io.lettuce.core.ClientOptions;
import io.lettuce.core.SocketOptions;
import io.micronaut.context.annotation.Bean;
import io.micronaut.context.annotation.ConfigurationProperties;
import io.micronaut.context.annotation.Primary;
import io.micronaut.runtime.context.scope.Refreshable;

import java.time.Duration;

@ConfigurationProperties("redis")
@Refreshable
public class RedisConfig {
    private String host = "redis.home.arpa";
    private int port = 30379;
    private String password = "Admin@123";
    private Duration timeout = Duration.ofSeconds(30);

    public String getHost() {
        return host;
    }

    public void setHost(String host) {
        this.host = host;
    }

    public int getPort() {
        return port;
    }

    public void setPort(int port) {
        this.port = port;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public Duration getTimeout() {
        return timeout;
    }

    public void setTimeout(Duration timeout) {
        this.timeout = timeout;
    }
}
