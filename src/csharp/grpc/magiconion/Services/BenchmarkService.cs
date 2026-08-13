using MagicOnion;
using MagicOnion.Server;
using MagicOnionBenchmark.Contracts;
using MagicOnionBenchmark;

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

    // Database and Cache were the literals "connected", with no I/O of any kind, so
    // this RPC reported health it had never checked -- invariante 6 in
    // docs/ACTION_PLAN.md, an implementation that does not implement. The Rust
    // tonic sibling pings both for this same RPC.
    public async UnaryResult<HealthResponse> HealthAsync()
    {
        var dbOk = await _database.PingAsync();
        var cacheOk = await _cache.PingAsync();

        return new HealthResponse
        {
            Status = dbOk && cacheOk ? "ok" : "degraded",
            Version = _version,
            Timestamp = DateTime.UtcNow.ToString("o"),
            Database = dbOk ? "connected" : "disconnected",
            Cache = cacheOk ? "connected" : "disconnected"
        };
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
                Uuid = Canonical.Uuid(i),
                Name = Canonical.Name(i),
                Email = Canonical.Email(i),
                CreatedAt = Canonical.CreatedAt,
                IsActive = Canonical.IsActive(i)
            });
        }

        return UnaryResult.FromResult(new JsonItemsResponse
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
