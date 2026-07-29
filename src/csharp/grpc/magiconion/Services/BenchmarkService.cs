using MagicOnion;
using MagicOnion.Server;
using MagicOnionBenchmark.Contracts;

namespace MagicOnionBenchmark.Services;

public class BenchmarkServiceImpl : ServiceBase<IBenchmarkService>, IBenchmarkService
{
    private readonly DatabaseService _database;
    private readonly CacheService _cache;
    private readonly string _version = "1.0.0";

    public BenchmarkServiceImpl(DatabaseService database, CacheService cache)
    {
        _database = database;
        _cache = cache;
    }

    public UnaryResult<HealthResponse> HealthAsync()
    {
        return UnaryResult(new HealthResponse
        {
            Status = "ok",
            Version = _version,
            Timestamp = DateTime.UtcNow.ToString("o"),
            Database = "connected",
            Cache = "connected"
        });
    }

    public UnaryResult<JsonItemsResponse> GetJsonItemsAsync(int limit)
    {
        var count = limit > 0 ? limit : 1000;
        var items = new List<JsonItem>();

        for (int i = 0; i < count; i++)
        {
            items.Add(new JsonItem
            {
                Id = i,
                Uuid = Guid.NewGuid().ToString(),
                Name = $"User_{i}",
                Email = $"user{i}@example.com",
                CreatedAt = DateTime.UtcNow.ToString("o"),
                IsActive = i % 2 == 0
            });
        }

        return UnaryResult(new JsonItemsResponse
        {
            Items = items,
            Count = items.Count,
            Timestamp = DateTime.UtcNow.ToString("o")
        });
    }

    public async UnaryResult<UserResponse> GetUserAsync(int id)
    {
        return await _database.GetUserAsync(id);
    }

    public async UnaryResult<ComplexOrdersResponse> GetComplexOrdersAsync(int days)
    {
        var d = days > 0 ? days : 30;
        return await _database.GetComplexOrdersAsync(d);
    }

    public async UnaryResult<CacheResponse> GetCacheValueAsync(string key)
    {
        return await _cache.GetAsync(key);
    }
}
