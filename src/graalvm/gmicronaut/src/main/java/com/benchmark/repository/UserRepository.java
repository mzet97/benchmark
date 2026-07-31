package com.benchmark.repository;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface UserRepository extends CrudRepository<User, Integer> {
    @Query("SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = :id")
    Optional<User> findByIdRaw(Integer id);

    @Query(value = """
        SELECT
            u.id as user_id,
            CONCAT(u.first_name, ' ', u.last_name) as user_name,
            COUNT(DISTINCT o.id) as total_orders,
            COALESCE(SUM(oi.quantity * oi.price), 0) as total_value,
            COALESCE(AVG(oi.quantity * oi.price), 0) as average_value
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
            AND o.created_at >= NOW() - (INTERVAL '1 day' * :days)
            AND o.status = 'completed'
        LEFT JOIN order_items oi ON o.id = oi.order_id
        WHERE o.id IS NULL OR (o.created_at >= NOW() - (INTERVAL '1 day' * :days) AND o.status = 'completed')
        GROUP BY u.id, u.first_name, u.last_name
        HAVING COUNT(DISTINCT o.id) > 0
        ORDER BY total_value DESC
        LIMIT 100
        """, nativeQuery = true)
    List<UserStats> findUserStats(Integer days);
}
