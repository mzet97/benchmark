package com.benchmark.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import io.micronaut.context.annotation.Factory;
import io.micronaut.context.annotation.Primary;
import io.micronaut.context.annotation.Requires;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

import javax.sql.DataSource;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

/**
 * Builds the {@code default} {@link DataSource} from the {@code DATABASE_URL}
 * environment variable.
 *
 * <p>The shared Kubernetes secret ({@code benchmark-secrets}) only ever exposes
 * {@code DATABASE_URL} in the Heroku/postgresql:// form; the {@code DB_HOST},
 * {@code DB_PORT}, {@code DB_NAME} and {@code DB_USER} variables that the
 * previous {@code application.yml} referenced do not exist in the deploy, so
 * Micronaut could not resolve the {@code datasources.default} placeholders and
 * threw "Failed to inject value for parameter [dataSource]" -- taking down
 * {@code /health}, {@code /db/simple} and {@code /db/complex} while
 * {@code /json} and {@code /cache} (no DataSource) kept working.
 *
 * <p>Parsing the URL here (rather than in YAML) also sidesteps the
 * percent-encoded password problem and the missing {@code jdbc:} prefix. The
 * bean is {@link Primary} and qualified as {@code "default"} so every
 * {@code @Named("default") DataSource} injection point resolves to it.
 */
@Factory
@Requires(property = "DATABASE_URL")
public class DatasourceFactory {

    static final String DATABASE_URL_ENV = "DATABASE_URL";

    @Named("default")
    @Primary
    @Singleton
    public DataSource dataSource() {
        return parseDatabaseUrl(System.getenv(DATABASE_URL_ENV));
    }

    static HikariDataSource parseDatabaseUrl(String databaseUrl) {
        if (databaseUrl == null || databaseUrl.isBlank()) {
            throw new IllegalStateException(
                DATABASE_URL_ENV + " is not set; cannot configure the DataSource");
        }

        // Accept both "postgresql://..." (the secret form) and "jdbc:postgresql://..."
        String spec = databaseUrl;
        if (spec.startsWith("jdbc:")) {
            spec = spec.substring("jdbc:".length());
        }
        if (!spec.startsWith("postgresql://")) {
            throw new IllegalStateException(
                "Unsupported " + DATABASE_URL_ENV + " scheme (expected postgresql://): " + spec);
        }

        // Use URI parsing: postgresql://user:pass@host:port/db?params
        URI uri = URI.create(spec);
        String host = uri.getHost();
        int port = uri.getPort();
        String userInfo = uri.getUserInfo();
        String path = uri.getPath();

        if (host == null || host.isEmpty()) {
            throw new IllegalStateException("No host in " + DATABASE_URL_ENV + ": " + databaseUrl);
        }
        if (port < 0) {
            port = 5432;
        }

        String username = null;
        String password = null;
        if (userInfo != null && !userInfo.isEmpty()) {
            int colon = userInfo.indexOf(':');
            if (colon < 0) {
                username = decode(userInfo);
            } else {
                username = decode(userInfo.substring(0, colon));
                password = decode(userInfo.substring(colon + 1));
            }
        }

        String database = "";
        if (path != null && path.startsWith("/")) {
            database = path.substring(1);
        }

        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:postgresql://" + host + ":" + port + "/" + database);
        config.setDriverClassName("org.postgresql.Driver");
        if (username != null) {
            config.setUsername(username);
        }
        if (password != null) {
            config.setPassword(password);
        }

        String poolMax = System.getenv("DB_POOL_MAX");
        if (poolMax != null && !poolMax.isBlank()) {
            config.setMaximumPoolSize(Integer.parseInt(poolMax.trim()));
        } else {
            config.setMaximumPoolSize(32);
        }
        config.setMinimumIdle(config.getMaximumPoolSize());

        config.setPoolName("benchmark-hikari");
        return new HikariDataSource(config);
    }

    private static String decode(String value) {
        return URLDecoder.decode(value, StandardCharsets.UTF_8);
    }
}
