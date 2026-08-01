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
        -- Normative SQL, see contracts/rest/canonical-payloads.md. The previous
        -- query joined order_items, aggregated quantity*price and ordered without
        -- a tiebreak, so it ran a heavier query than the other implementations and
        -- its rows came back in arbitrary order among equal values.
        SELECT
            u.id AS "userId",
            u.first_name || ' ' || u.last_name AS "userName",
            COUNT(o.id) AS "totalOrders",
            COALESCE(SUM(o.total_amount), 0) AS "totalValue",
            COALESCE(AVG(o.total_amount), 0) AS "averageOrderValue"
        FROM users u
        INNER JOIN orders o ON u.id = o.user_id
            WHERE o.created_at >= NOW() - INTERVAL '1 day' * :days
        GROUP BY u.id, u.first_name, u.last_name
        ORDER BY "totalOrders" DESC, u.id
        LIMIT 100
        """, nativeQuery = true)
    List<UserStats> findUserStats(Integer days);
}
