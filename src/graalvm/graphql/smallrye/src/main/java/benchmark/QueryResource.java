package benchmark;

import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Query;

import jakarta.inject.Inject;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@GraphQLApi
public class QueryResource {

    @Inject
    DatabaseService databaseService;

    @Inject
    CacheService cacheService;

    @Query("health")
    public Models.Health health() {
        return new Models.Health(
                "ok",
                "1.0.0",
                Instant.now().toString(),
                databaseService.checkHealth(),
                cacheService.checkHealth()
        );
    }

    @Query("jsonItems")
    public Models.JsonItemsResult jsonItems(int limit) {
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

    @Query("user")
    public Models.User user(int id) {
        return databaseService.getUser(id);
    }

    @Query("complexOrders")
    public Models.ComplexOrdersResult complexOrders(int days) {
        return databaseService.getComplexOrders(days);
    }

    @Query("cache")
    public Models.CacheEntry cache(String key) {
        return cacheService.getCacheEntry(key);
    }
}
