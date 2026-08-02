package benchmark;

import graphql.GraphQL;
import graphql.schema.GraphQLSchema;
import graphql.schema.idl.RuntimeWiring;
import graphql.schema.idl.SchemaGenerator;
import graphql.schema.idl.SchemaParser;
import graphql.schema.idl.TypeDefinitionRegistry;
import io.micronaut.context.annotation.Bean;
import io.micronaut.context.annotation.Factory;
import io.micronaut.core.io.ResourceResolver;

import jakarta.inject.Inject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Factory
public class GraphQLFactory {

    @Inject
    private DatabaseService databaseService;

    @Inject
    private CacheService cacheService;

    @Bean
    public GraphQL graphQL(ResourceResolver resourceResolver) {
        String schemaString = new BufferedReader(
                new InputStreamReader(
                        resourceResolver.getResourceAsStream("classpath:graphql/schema.graphqls").orElseThrow(),
                        StandardCharsets.UTF_8
                )
        ).lines().collect(Collectors.joining("\n"));

        SchemaParser schemaParser = new SchemaParser();
        TypeDefinitionRegistry typeDefinitionRegistry = schemaParser.parse(schemaString);

        RuntimeWiring runtimeWiring = RuntimeWiring.newRuntimeWiring()
                .type("Query", builder -> builder
                        .dataFetcher("health", env -> {
                            return new Models.Health(
                                    "ok",
                                    "1.0.0",
                                    Instant.now().toString(),
                                    databaseService.checkHealth(),
                                    cacheService.checkHealth()
                            );
                        })
                        .dataFetcher("jsonItems", env -> {
                            int limit = env.getArgument("limit") != null ? (int) env.getArgument("limit") : 1000;
                            if (limit <= 0) limit = 1000;
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
                        })
                        .dataFetcher("user", env -> {
                            int id = (int) env.getArgument("id");
                            return databaseService.getUser(id);
                        })
                        .dataFetcher("complexOrders", env -> {
                            int days = env.getArgument("days") != null ? (int) env.getArgument("days") : 30;
                            List<Models.UserOrderStats> data = databaseService.getComplexOrders(days);
                            return new Models.ComplexOrdersResult(days, data.size(), data);
                        })
                        .dataFetcher("cache", env -> {
                            String key = (String) env.getArgument("key");
                            return cacheService.getCacheEntry(key);
                        })
                )
                .build();

        SchemaGenerator schemaGenerator = new SchemaGenerator();
        GraphQLSchema graphQLSchema = schemaGenerator.makeExecutableSchema(typeDefinitionRegistry, runtimeWiring);

        return GraphQL.newGraphQL(graphQLSchema)
                .build();
    }
}
