package benchmark;

import graphql.schema.DataFetchingEnvironment;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.Map;

@Singleton
public class QueryController {

    @Inject
    private DatabaseService databaseService;

    @Inject
    private CacheService cacheService;

    public Models.Health health() {
        return new Models.Health(
                "ok",
                "1.0.0",
                Instant.now().toString(),
                databaseService.checkHealth(),
                cacheService.checkHealth()
        );
    }

    public Models.JsonItemsResult jsonItems(int limit) {
        int count = Canonical.itemCount(limit);
        List<Models.JsonItem> items = new ArrayList<>(count);
        for (int i = 0; i < count; i++) {
            items.add(new Models.JsonItem(
                    i,
                    Canonical.uuid(i),
                    Canonical.name(i),
                    Canonical.email(i),
                    Canonical.CREATED_AT,
                    Canonical.isActive(i)
            ));
        }
        return new Models.JsonItemsResult(items, items.size(), Instant.now().toString());
    }

    public Models.User user(int id) {
        return databaseService.getUser(id);
    }

    public Models.ComplexOrdersResult complexOrders(int days) {
        List<Models.UserOrderStats> data = databaseService.getComplexOrders(days);
        return new Models.ComplexOrdersResult(days, data.size(), data);
    }

    public Models.CacheEntry cache(String key) {
        return cacheService.getCacheEntry(key);
    }
}
