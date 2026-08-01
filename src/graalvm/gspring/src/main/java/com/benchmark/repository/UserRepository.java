package com.benchmark.repository;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends CrudRepository<User, Integer> {
    @Query(value = "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?1", nativeQuery = true)
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
            WHERE o.created_at >= NOW() - INTERVAL '1 day' * ?1
        GROUP BY u.id, u.first_name, u.last_name
        ORDER BY "totalOrders" DESC, u.id
        LIMIT 100
        """, nativeQuery = true)
    List<UserStats> findUserStats(Integer days);
}
