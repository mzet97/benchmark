using GraphqlHotChocolate.Services;

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

    public async Task<ComplexOrdersResult> GetComplexOrders(
        int days = 30,
        [Service] DatabaseService db)
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
            Ttl = ttl >= 0 ? ttl : 0
        };
    }
}
