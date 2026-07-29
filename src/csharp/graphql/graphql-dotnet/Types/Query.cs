using GraphQL;
using GraphQL.Types;
using GraphqlDotnet.Services;

namespace GraphqlDotnet.Types;

public class QueryType : ObjectGraphType
{
    public QueryType(DatabaseService db, CacheService cache)
    {
        Name = "Query";

        Field<NonNullGraphType<HealthType>>("health")
            .ResolveAsync(async context =>
            {
                var dbStatus = "ok";
                var cacheStatus = "ok";

                try { await db.PingAsync(); }
                catch { dbStatus = "error"; }

                try { await cache.PingAsync(); }
                catch { cacheStatus = "error"; }

                return new Health
                {
                    Status = "ok",
                    Version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0",
                    Timestamp = DateTime.UtcNow.ToString("o"),
                    Database = dbStatus,
                    Cache = cacheStatus
                };
            });

        Field<NonNullGraphType<JsonItemsResultType>>("jsonItems")
            .Argument<NonNullGraphType<IntGraphType>>("limit", arg => arg.DefaultValue = 1000)
            .Resolve(context =>
            {
                var limit = context.GetArgument<int>("limit");
                var items = new List<JsonItem>(limit);
                for (var i = 0; i < limit; i++)
                {
                    items.Add(new JsonItem
                    {
                        Id = i + 1,
                        Uuid = $"item-{i + 1}-uuid",
                        Name = $"Item {i + 1}",
                        Email = $"item{i + 1}@example.com",
                        CreatedAt = DateTime.UtcNow.ToString("o"),
                        IsActive = i % 2 == 0
                    });
                }

                return new JsonItemsResult
                {
                    Items = items,
                    Count = items.Count,
                    Timestamp = DateTime.UtcNow.ToString("o")
                };
            });

        Field<UserType>("user")
            .Argument<NonNullGraphType<IntGraphType>>("id")
            .ResolveAsync(async context =>
            {
                var id = context.GetArgument<int>("id");
                return await db.GetUserByIdAsync(id);
            });

        Field<NonNullGraphType<ComplexOrdersResultType>>("complexOrders")
            .Argument<NonNullGraphType<IntGraphType>>("days", arg => arg.DefaultValue = 30)
            .ResolveAsync(async context =>
            {
                var days = context.GetArgument<int>("days");
                var data = await db.GetComplexOrdersAsync(days);
                return new ComplexOrdersResult
                {
                    PeriodDays = days,
                    TotalUsers = data.Count,
                    Data = data
                };
            });

        Field<NonNullGraphType<CacheEntryType>>("cache")
            .Argument<NonNullGraphType<StringGraphType>>("key")
            .ResolveAsync(async context =>
            {
                var key = context.GetArgument<string>("key")!;
                var value = await cache.GetAsync(key);
                var ttl = await cache.GetTtlAsync(key);

                if (value != null)
                {
                    return new CacheEntry
                    {
                        Key = key,
                        Value = value,
                        Cached = true,
                        Ttl = ttl >= 0 ? (int)ttl : 0
                    };
                }

                // Generate value on miss
                var generatedValue = $"value-for-{key}";
                await cache.SetAsync(key, generatedValue, 300);

                return new CacheEntry
                {
                    Key = key,
                    Value = generatedValue,
                    Cached = false,
                    Ttl = 300
                };
            });
    }
}
