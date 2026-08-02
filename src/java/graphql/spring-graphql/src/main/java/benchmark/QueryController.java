package benchmark;

import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Controller
public class QueryController {

    private final DatabaseService databaseService;
    private final CacheService cacheService;

    public QueryController(DatabaseService databaseService, CacheService cacheService) {
        this.databaseService = databaseService;
        this.cacheService = cacheService;
    }

    @QueryMapping
    public Models.Health health() {
        return new Models.Health(
                "ok",
                "1.0.0",
                Instant.now().toString(),
                databaseService.checkHealth(),
                cacheService.checkHealth()
        );
    }

    @QueryMapping
    public Models.JsonItemsResult jsonItems(@Argument int limit) {
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

    @QueryMapping
    public Models.User user(@Argument int id) {
        return databaseService.getUser(id);
    }

    @QueryMapping
    public Models.ComplexOrdersResult complexOrders(@Argument int days) {
        return databaseService.getComplexOrders(days);
    }

    @QueryMapping
    public Models.CacheEntry cache(@Argument String key) {
        return cacheService.getCacheEntry(key);
    }
}
