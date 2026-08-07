package com.benchmark.api.service;

import com.benchmark.api.model.ComplexOrderResult;
import com.benchmark.api.model.User;
import io.smallrye.mutiny.Uni;
import io.vertx.mutiny.pgclient.PgPool;
import io.vertx.mutiny.sqlclient.Row;
import io.vertx.mutiny.sqlclient.RowSet;
import io.vertx.mutiny.sqlclient.Tuple;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@ApplicationScoped
public class DatabaseService {

    private static final Logger LOG = LoggerFactory.getLogger(DatabaseService.class);

    @Inject
    PgPool client;

    public Uni<User> findUserById(Integer id) {
        String query = "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1";

        return client.preparedQuery(query)
                .execute(Tuple.of(id))
                .map(RowSet::iterator)
                .map(iterator -> {
                    if (iterator.hasNext()) {
                        Row row = iterator.next();
                        return mapUser(row);
                    }
                    return null;
                })
                .onFailure().recoverWithItem(t -> {
                    LOG.error("Error fetching user: {}", t.getMessage());
                    return null;
                });
    }

    public Uni<List<ComplexOrderResult>> findComplexOrders(Integer days) {
        String query = """
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
                WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY "totalOrders" DESC, u.id
            LIMIT 100
            """;

        return client.preparedQuery(query)
                .execute(Tuple.of(days))
                .map(this::mapComplexResults)
                .onFailure().recoverWithItem(t -> {
                    LOG.error("Error fetching complex orders: {}", t.getMessage());
                    return new ArrayList<>();
                });
    }

    public Uni<Boolean> healthCheck() {
        return client.query("SELECT 1")
                .execute()
                .map(rows -> rows.size() > 0)
                .onFailure().recoverWithItem(false);
    }

    private User mapUser(Row row) {
        return new User(
                row.getInteger("id"),
                row.getString("email"),
                row.getString("first_name"),
                row.getString("last_name"),
                row.getInteger("age"),
                row.getOffsetDateTime("created_at").toString()
        );
    }

    private List<ComplexOrderResult> mapComplexResults(RowSet<Row> rows) {
        List<ComplexOrderResult> results = new ArrayList<>();
        for (Row row : rows) {
            results.add(new ComplexOrderResult(
                    row.getInteger("userId"),
                    row.getString("userName"),
                    row.getLong("totalOrders"),
                    row.getDouble("totalValue"),
                    row.getDouble("averageOrderValue")
            ));
        }
        return results;
    }
}
