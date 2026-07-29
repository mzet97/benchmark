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
