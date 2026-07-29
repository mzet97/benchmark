package benchmark;

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
    PgPool pgClient;

    public Uni<String> healthCheck() {
        return pgClient.query("SELECT 1").execute()
                .onItem().transform(rows -> rows.size() > 0 ? "connected" : "disconnected")
                .onFailure().recoverWithItem("disconnected");
    }

    public Uni<User> getUser(int id) {
        return pgClient.preparedQuery(
                        "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1")
                .execute(Tuple.of(id))
                .onItem().transform(RowSet::iterator)
                .onItem().transform(iterator -> iterator.hasNext() ? fromRow(iterator.next()) : null);
    }

    public Uni<List<UserOrderStat>> getComplexOrders(int days) {
        return pgClient.preparedQuery(
                        "SELECT " +
                        "u.id as user_id, " +
                        "u.first_name || ' ' || u.last_name as user_name, " +
                        "COUNT(o.id) as total_orders, " +
                        "COALESCE(SUM(o.total_amount), 0) as total_value, " +
                        "COALESCE(AVG(o.total_amount), 0) as average_order_value " +
                        "FROM users u " +
                        "LEFT JOIN orders o ON u.id = o.user_id " +
                        "AND o.created_at >= NOW() - INTERVAL '$1 days' " +
                        "GROUP BY u.id, u.first_name, u.last_name " +
                        "HAVING COUNT(o.id) > 0 " +
                        "ORDER BY total_value DESC " +
                        "LIMIT 100")
                .execute(Tuple.of(days))
                .onItem().transform(rows -> {
                    List<UserOrderStat> results = new ArrayList<>();
                    for (Row row : rows) {
                        results.add(new UserOrderStat(
                                row.getInteger("user_id"),
                                row.getString("user_name"),
                                row.getInteger("total_orders"),
                                row.getDouble("total_value"),
                                row.getDouble("average_order_value")
                        ));
                    }
                    return results;
                });
    }

    private User fromRow(Row row) {
        return new User(
                row.getInteger("id"),
                row.getString("email"),
                row.getString("first_name"),
                row.getString("last_name"),
                row.getInteger("age"),
                row.getLocalDateTime("created_at") != null
                        ? row.getLocalDateTime("created_at").toString()
                        : ""
        );
    }

    public static class User {
        private final int id;
        private final String email;
        private final String firstName;
        private final String lastName;
        private final int age;
        private final String createdAt;

        public User(int id, String email, String firstName, String lastName, int age, String createdAt) {
            this.id = id;
            this.email = email;
            this.firstName = firstName;
            this.lastName = lastName;
            this.age = age;
            this.createdAt = createdAt;
        }

        public int getId() { return id; }
        public String getEmail() { return email; }
        public String getFirstName() { return firstName; }
        public String getLastName() { return lastName; }
        public int getAge() { return age; }
        public String getCreatedAt() { return createdAt; }
    }

    public static class UserOrderStat {
        private final int userId;
        private final String userName;
        private final int totalOrders;
        private final double totalValue;
        private final double averageOrderValue;

        public UserOrderStat(int userId, String userName, int totalOrders, double totalValue, double averageOrderValue) {
            this.userId = userId;
            this.userName = userName;
            this.totalOrders = totalOrders;
            this.totalValue = totalValue;
            this.averageOrderValue = averageOrderValue;
        }

        public int getUserId() { return userId; }
        public String getUserName() { return userName; }
        public int getTotalOrders() { return totalOrders; }
        public double getTotalValue() { return totalValue; }
        public double getAverageOrderValue() { return averageOrderValue; }
    }
}
