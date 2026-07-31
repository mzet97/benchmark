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
            SELECT
                u.id as user_id,
                u.email,
                COUNT(o.id) as order_count,
                SUM(o.total_amount) as total_amount,
                AVG(o.total_amount) as avg_amount,
                EXTRACT(DAY FROM (NOW() - MIN(o.created_at))) as days_since_first_order
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
            WHERE o.created_at >= NOW() - ($1 || ' days')::INTERVAL
            GROUP BY u.id, u.email
            ORDER BY order_count DESC
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
                    row.getInteger("user_id"),
                    row.getString("email"),
                    row.getLong("order_count"),
                    row.getDouble("total_amount"),
                    row.getDouble("avg_amount"),
                    row.getLong("days_since_first_order")
            ));
        }
        return results;
    }
}
