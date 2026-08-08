package com.benchmark.config

import org.springframework.boot.autoconfigure.ImportAutoConfiguration
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
import org.springframework.boot.autoconfigure.jdbc.JdbcTemplateAutoConfiguration
import org.springframework.context.annotation.Configuration

/**
 * DataSource/JdbcTemplate are auto-configured by Spring Boot from
 * application.properties (spring.datasource.*), which builds the JDBC url from
 * the DB_HOST/DB_PORT/DB_NAME component variables.
 *
 * Previously this class declared its own @Bean DataSource using
 * DriverManagerDataSource with System.getenv("DATABASE_URL"). That URL has no
 * "jdbc:" prefix (it is a bare "postgresql://..." URL), so the Postgres driver
 * rejected it, every connection threw, and /health reported database:unhealthy
 * while /db/simple and /db/complex returned 500. The manual bean also shadowed
 * HikariCP (DriverManagerDataSource has no pool). Dropping the manual bean lets
 * Spring Boot wire the Hikari DataSource that application.properties already
 * configures correctly. We only make the autoconfig explicit here so the
 * override can never silently come back.
 */
@Configuration
@ImportAutoConfiguration(DataSourceAutoConfiguration::class, JdbcTemplateAutoConfiguration::class)
class DatabaseConfig
