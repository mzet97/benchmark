using EntityGraphQL.Schema;
using GraphqlEntityGraphQL.Models;
using GraphqlEntityGraphQL.Services;

namespace GraphqlEntityGraphQL.Schema;

/// <summary>
/// Configures the GraphQL schema on top of <see cref="BenchmarkContext"/>.
///
/// EntityGraphQL 5.x compiles every field resolver into an expression tree, so
/// resolvers must be expression-body lambdas: no statement bodies, no assignment
/// operators, and no async/await. Async data access (Postgres, Redis) is done by
/// calling the async service methods and unwrapping the Task synchronously with
/// <c>.GetAwaiter().GetResult()</c> -- the documented 5.x pattern (see
/// EntityGraphQL.AspNet tests/QueryTests/AsyncTests.cs). EntityGraphQL executes
/// the resulting expression tree itself.
///
/// Fields that resolve data through a service use <c>Resolve&lt;TService&gt;</c>
/// so the service is injected from the request's <see cref="IServiceProvider"/>.
/// The query-context object (<see cref="BenchmarkContext"/>) is supplied by the
/// ASP.NET integration but carries no data here -- every resolver works through
/// the injected services.
/// </summary>
public class BenchmarkSchema
{
    /// <summary>
    /// Builds and configures the <see cref="SchemaProvider{BenchmarkContext}"/>.
    /// Registered via <c>AddGraphQLSchema&lt;BenchmarkContext&gt;(Configure)</c>.
    /// </summary>
    public static SchemaProvider<BenchmarkContext> Configure(DatabaseService db, CacheService cache, bool introspectionEnabled = true)
    {
        var schema = new SchemaProvider<BenchmarkContext>(introspectionEnabled: introspectionEnabled);

        // Result types are returned by service-resolved fields, which EntityGraphQL
        // cannot infer from the empty context -- register them explicitly.
        schema.AddType<Health>("Health", "Health check endpoint").AddAllFields();
        schema.AddType<JsonItem>("JsonItem", "A canonical JSON benchmark item").AddAllFields();
        schema.AddType<JsonItemsResult>("JsonItemsResult", "JSON serialization benchmark result").AddAllFields();
        schema.AddType<User>("User", "Application user").AddAllFields();
        schema.AddType<UserOrderStats>("UserOrderStats", "Per-user order aggregation").AddAllFields();
        schema.AddType<ComplexOrdersResult>("ComplexOrdersResult", "Complex orders aggregation result").AddAllFields();
        schema.AddType<CacheEntry>("CacheEntry", "Cache hit/miss benchmark entry").AddAllFields();

        // -- health: pure expression, no service or wall clock dependency --------
        schema.Query().AddField("health", new { }, (ctx, args) => new Health
        {
            Status = "ok",
            Version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0",
            Timestamp = DateTime.UtcNow.ToString("o"),
            Database = "ok",
            Cache = "ok"
        }, "Health check endpoint");

        // -- jsonItems: CPU-only generation, no I/O ------------------------------
        schema.Query().AddField("jsonItems", new { limit = 1000 }, (ctx, args) => new JsonItemsResult
        {
            Items = Canonical.BuildItems(args.limit),
            Count = Canonical.ItemCount(args.limit),
            Timestamp = DateTime.UtcNow.ToString("o")
        }, "JSON serialization benchmark with 1000 objects");

        // -- user: Postgres lookup ------------------------------------------------
        // Per the contract `user(id): User` is nullable (no "!"), so returning
        // null on a missing user is correct; the pragma silences the NRT warning
        // that fires because the resolver delegate's return type is non-null.
        schema.Query().AddField("user", new { id = 0 }, "Get a user by ID")
#pragma warning disable CS8603
            .Resolve<DatabaseService>((ctx, args, database) => database.GetUserById(args.id));
#pragma warning restore CS8603

        // -- complexOrders: Postgres aggregation ----------------------------------
        schema.Query().AddField("complexOrders", new { days = 30 }, "Complex orders aggregation query")
            .Resolve<DatabaseService>((ctx, args, database) => new ComplexOrdersResult
            {
                PeriodDays = args.days,
                TotalUsers = database.GetComplexOrders(args.days).Count,
                Data = database.GetComplexOrders(args.days)
            });

        // -- cache: Redis hit/miss with write-on-miss -----------------------------
        schema.Query().AddField("cache", new { key = "" }, "Cache hit/miss benchmark")
            .Resolve<CacheService>((ctx, args, redis) => redis.GetOrSet(args.key, 300));

        return schema;
    }
}

/// <summary>
/// Root query context for EntityGraphQL. Carries no data itself; all field
/// resolvers obtain data through injected services. Must be registered in DI so
/// the ASP.NET integration can supply the context instance per request.
/// </summary>
public class BenchmarkContext
{
}
