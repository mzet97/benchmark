package com.benchmark.repository;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;

import java.util.List;
import java.util.Optional;

// Extends no CrudRepository: the only methods used are the two @Query ones
// below (DatabaseService calls findByIdRaw/findUserStats, nothing else).
// Extending CrudRepository<User, Integer> made the micronaut-data-processor
// try to implement save()/update() for a User that has no @MappedEntity/@Id
// mapping, which aborted the build with "Unsupported return type for a save
// method: com.benchmark.model.User". A standalone @JdbcRepository with
// hand-written queries is enough and keeps User a plain serialization DTO.
@JdbcRepository(dialect = Dialect.POSTGRES)
public interface UserRepository {
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
