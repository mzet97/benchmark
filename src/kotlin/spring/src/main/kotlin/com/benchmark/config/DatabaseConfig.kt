package com.benchmark.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.jdbc.datasource.DriverManagerDataSource
import javax.sql.DataSource

@Configuration
class DatabaseConfig {
    @Bean
    fun dataSource(): DataSource {
        val dataSource = DriverManagerDataSource()
        dataSource.setDriverClassName("org.postgresql.Driver")
        dataSource.url = System.getenv("DATABASE_URL") ?: "jdbc:postgresql://spsql.home.arpa:5432/benchmark_api"
        dataSource.username = System.getenv("DB_USER") ?: "app"
        dataSource.password = System.getenv("DB_PASSWORD") ?: "Admin@123"
        return dataSource
    }

    @Bean
    fun jdbcTemplate(dataSource: DataSource): JdbcTemplate {
        return JdbcTemplate(dataSource)
    }
}
