using GraphqlHotChocolate.Services;
using GraphqlHotChocolate;

namespace GraphqlHotChocolate.Types;

public class Query
{
    public async Task<Health> GetHealth(
        [Service] DatabaseService db,
        [Service] CacheService cache)
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
    }

    public JsonItemsResult GetJsonItems(int limit = 1000)
    {
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
    }

    // Goes straight to Postgres, with no Redis layer in front of it.
    //
    // This resolver used to check Redis for "user:{id}", return the deserialized
    // JSON on a hit, and write through with a 60 s TTL on a miss. No other
    // implementation of this field does that -- graphql-dotnet
    // (Types/Query.cs:65-71) and Go's gqlgen both query the database on every
    // call, and neither contracts/graphql/schema.graphql nor
    // contracts/rest/canonical-payloads.md mentions caching here.
    //
    // The benchmark drives this field with a repeating id, so after the first
    // request every subsequent one was answered from Redis. The number published
    // for this implementation measured a Redis GET while every peer's measured a
    // Postgres query -- the two are not the same question, and the faster one
    // looked like a framework win. Caching that only one implementation has is
    // the same class of defect as an endpoint that returns an empty payload: the
    // figure is real, it just does not mean what the ranking says it means.
    public async Task<User?> GetUser(
        int id,
        [Service] DatabaseService db)
    {
        return await db.GetUserByIdAsync(id);
    }

    // The injected service has to come before the optional argument: C# does
    // not allow a required parameter after an optional one, so this method
    // never compiled.
    public async Task<ComplexOrdersResult> GetComplexOrders(
        [Service] DatabaseService db,
        int days = 30)
    {
        var data = await db.GetComplexOrdersAsync(days);
        return new ComplexOrdersResult
        {
            PeriodDays = days,
            TotalUsers = data.Count,
            Data = data
        };
    }

    public async Task<CacheEntry> GetCache(
        string key,
        [Service] CacheService cache)
    {
        var value = await cache.GetAsync(key);
        var ttl = await cache.GetTtlAsync(key);

        return new CacheEntry
        {
            Key = key,
            Value = value ?? "",
            Cached = value != null,
            Ttl = ttl >= 0 ? (int)ttl : 0
        };
    }
}
