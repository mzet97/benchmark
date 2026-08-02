using EntityGraphQL.Schema;
using GraphqlEntityGraphQL.Models;
using GraphqlEntityGraphQL.Services;
using GraphqlEntityGraphQL;

namespace GraphqlEntityGraphQL.Schema;

public static class BenchmarkSchema
{
    public static SchemaProvider<BenchmarkContext> Create(DatabaseService db, CacheService cache)
    {
        var schema = new SchemaProvider<BenchmarkContext>();

        // Health query
        schema.Query().AddField("health", new { }, (p, args) => new Health
        {
            Status = "ok",
            Version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0",
            Timestamp = DateTime.UtcNow.ToString("o"),
            Database = "ok",
            Cache = "ok"
        }, "Health check endpoint");

        // JsonItems query
        schema.Query().AddField("jsonItems", new { limit = 1000 }, (p, args) =>
        {
            var limit = args.limit;
            var count = Canonical.ItemCount(limit);
            var items = new List<JsonItem>(count);
            for (var i = 0; i < count; i++)
            {
                items.Add(new JsonItem
                {
                    Id = i,
                    Uuid = Canonical.Uuid(i),
                    Name = Canonical.Name(i),
                    Email = Canonical.Email(i),
                    CreatedAt = Canonical.CreatedAt,
                    IsActive = Canonical.IsActive(i)
                });
            }

            return new JsonItemsResult
            {
                Items = items,
                Count = items.Count,
                Timestamp = DateTime.UtcNow.ToString("o")
            };
        }, "JSON serialization benchmark with 1000 objects");

        // User query
        schema.Query().AddField("user", new { id = 0 }, async (p, args) =>
        {
            var user = await db.GetUserByIdAsync(args.id);
            return user;
        }, "Get a user by ID");

        // ComplexOrders query
        schema.Query().AddField("complexOrders", new { days = 30 }, async (p, args) =>
        {
            var data = await db.GetComplexOrdersAsync(args.days);
            return new ComplexOrdersResult
            {
                PeriodDays = args.days,
                TotalUsers = data.Count,
                Data = data
            };
        }, "Complex orders aggregation query");

        // Cache query
        schema.Query().AddField("cache", new { key = "" }, async (p, args) =>
        {
            var key = args.key;
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
        }, "Cache hit/miss benchmark");

        return schema;
    }
}

public class BenchmarkContext
{
}
