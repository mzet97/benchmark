package benchmark;

import dev.benchmark.grpc.Benchmark.*;
import io.smallrye.mutiny.Uni;
import io.vertx.mutiny.pgclient.PgPool;
import io.vertx.mutiny.sqlclient.Row;
import io.vertx.mutiny.sqlclient.RowSet;
import io.vertx.mutiny.sqlclient.Tuple;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.util.ArrayList;
import java.util.List;

@ApplicationScoped
public class DatabaseService {

    @Inject
    PgPool client;

    public Uni<UserResponse> getUser(int id) {
        return client.preparedQuery(
                "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1")
                .execute(Tuple.of(id))
                .onItem().transform(rows -> {
                    if (rows.iterator().hasNext()) {
                        Row row = rows.iterator().next();
                        return UserResponse.newBuilder()
                                .setId(row.getInteger("id"))
                                .setEmail(row.getString("email"))
                                .setFirstName(row.getString("first_name"))
                                .setLastName(row.getString("last_name"))
                                .setAge(row.getInteger("age"))
                                .setCreatedAt(row.getLocalDateTime("created_at").toString())
                                .build();
                    }
                    return UserResponse.getDefaultInstance();
                });
    }

    public Uni<ComplexOrdersResponse> getComplexOrders(int days) {
        String sql = """
                SELECT
                    u.id AS user_id,
                    u.first_name || ' ' || u.last_name AS user_name,
                    COUNT(o.id) AS total_orders,
                    COALESCE(SUM(o.total_amount), 0) AS total_value,
                    COALESCE(AVG(o.total_amount), 0) AS average_order_value
                FROM users u
                LEFT JOIN orders o ON u.id = o.user_id
                    AND o.created_at >= NOW() - INTERVAL '1 day' * $1
                GROUP BY u.id, u.first_name, u.last_name
                ORDER BY total_value DESC
                LIMIT 100
                """;

        return client.preparedQuery(sql)
                .execute(Tuple.of(days))
                .onItem().transform(rows -> {
                    ComplexOrdersResponse.Builder builder = ComplexOrdersResponse.newBuilder();
                    builder.setPeriodDays(days);

                    List<UserOrderStats> statsList = new ArrayList<>();
                    for (Row row : rows) {
                        statsList.add(UserOrderStats.newBuilder()
                                .setUserId(row.getInteger("user_id"))
                                .setUserName(row.getString("user_name"))
                                .setTotalOrders(row.getInteger("total_orders").intValue())
                                .setTotalValue(row.getDouble("total_value"))
                                .setAverageOrderValue(row.getDouble("average_order_value"))
                                .build());
                    }

                    builder.setTotalUsers(statsList.size());
                    builder.addAllData(statsList);
                    return builder.build();
                });
    }
}
