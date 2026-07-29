package benchmark;

import com.netflix.graphql.dgs.DgsComponent;
import com.netflix.graphql.dgs.DgsQuery;
import com.netflix.graphql.dgs.InputArgument;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@DgsComponent
public class QueryResolver {

    private final DatabaseService databaseService;
    private final CacheService cacheService;

    public QueryResolver(DatabaseService databaseService, CacheService cacheService) {
        this.databaseService = databaseService;
        this.cacheService = cacheService;
    }

    @DgsQuery
    public Models.Health health() {
        return new Models.Health(
                "ok",
                "1.0.0",
                Instant.now().toString(),
                databaseService.checkHealth(),
                cacheService.checkHealth()
        );
    }

    @DgsQuery
    public Models.JsonItemsResult jsonItems(@InputArgument int limit) {
        if (limit <= 0) limit = 1000;
        List<Models.JsonItem> items = new ArrayList<>(limit);
        for (int i = 0; i < limit; i++) {
            items.add(new Models.JsonItem(
                    i + 1,
                    UUID.randomUUID().toString(),
                    "Item " + (i + 1),
                    "user" + (i + 1) + "@example.com",
                    Instant.now().toString(),
                    i % 3 != 0
            ));
        }
        return new Models.JsonItemsResult(items, items.size(), Instant.now().toString());
    }

    @DgsQuery
    public Models.User user(@InputArgument int id) {
        return databaseService.getUser(id);
    }

    @DgsQuery
    public Models.ComplexOrdersResult complexOrders(@InputArgument int days) {
        List<Models.UserOrderStats> data = databaseService.getComplexOrders(days);
        return new Models.ComplexOrdersResult(days, data.size(), data);
    }

    @DgsQuery
    public Models.CacheEntry cache(@InputArgument String key) {
        return cacheService.getCacheEntry(key);
    }
}
