package benchmark;

import java.util.List;

public class Models {

    public record Health(
            String status,
            String version,
            String timestamp,
            String database,
            String cache
    ) {}

    public record JsonItem(
            int id,
            String uuid,
            String name,
            String email,
            String createdAt,
            boolean isActive
    ) {}

    public record JsonItemsResult(
            List<JsonItem> items,
            int count,
            String timestamp
    ) {}

    public record User(
            int id,
            String email,
            String firstName,
            String lastName,
            int age,
            String createdAt
    ) {}

    public record UserOrderStats(
            int userId,
            String userName,
            int totalOrders,
            double totalValue,
            double averageOrderValue
    ) {}

    public record ComplexOrdersResult(
            int periodDays,
            int totalUsers,
            List<UserOrderStats> data
    ) {}

    public record CacheEntry(
            String key,
            String value,
            boolean cached,
            int ttl
    ) {}
}
