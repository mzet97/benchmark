package com.benchmark.api;

import io.quarkus.runtime.ShutdownEvent;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class Application {

    private static final Logger LOG = LoggerFactory.getLogger(Application.class);

    void onStart(@Observes StartupEvent ev) {
        LOG.info("🚀 Benchmark Quarkus API starting...");
        LOG.info("✅ Quarkus version: {}", io.quarkus.runtime.Version.getVersion());
    }

    void onStop(@Observes ShutdownEvent ev) {
        LOG.info("🛑 Benchmark Quarkus API shutting down...");
    }
}
