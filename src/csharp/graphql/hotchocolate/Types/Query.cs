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

    public async Task<User?> GetUser(
        int id,
        [Service] DatabaseService db,
        [Service] CacheService cache)
    {
        var cached = await cache.GetAsync($"user:{id}");
        if (cached != null)
        {
            return System.Text.Json.JsonSerializer.Deserialize<User>(cached);
        }

        var result = await db.GetUserByIdAsync(id);
        if (result == null) return null;

        await cache.SetAsync($"user:{id}",
            System.Text.Json.JsonSerializer.Serialize(result), 60);
        return result;
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
