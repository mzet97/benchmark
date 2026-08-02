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
