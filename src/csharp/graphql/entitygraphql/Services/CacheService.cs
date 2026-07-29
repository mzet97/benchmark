using StackExchange.Redis;

namespace GraphqlEntityGraphQL.Services;

public class CacheService : IDisposable
{
    private readonly ConnectionMultiplexer _redis;
    private readonly IDatabase _db;

    public CacheService(IConfiguration configuration)
    {
        var redisUrl = configuration["REDIS_URL"] ?? "localhost:6379";
        _redis = ConnectionMultiplexer.Connect(redisUrl);
        _db = _redis.GetDatabase();
    }

    public async Task PingAsync()
    {
        await _db.PingAsync();
    }

    public async Task<string?> GetAsync(string key)
    {
        var value = await _db.StringGetAsync(key);
        return value.HasValue ? value.ToString() : null;
    }

    public async Task SetAsync(string key, string value, int ttlSeconds)
    {
        await _db.StringSetAsync(key, value, TimeSpan.FromSeconds(ttlSeconds));
    }

    public async Task<long> GetTtlAsync(string key)
    {
        var ttl = await _db.TimeToLiveAsync(key);
        return ttl?.TotalSeconds >= 0 ? (long)ttl.Value.TotalSeconds : -2;
    }

    public void Dispose()
    {
        _redis.Dispose();
    }
}
