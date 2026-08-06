using StackExchange.Redis;
using GraphqlEntityGraphQL.Models;

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
        var ttl = await _db.KeyTimeToLiveAsync(key);
        return ttl?.TotalSeconds >= 0 ? (long)ttl.Value.TotalSeconds : -2;
    }

    /// <summary>
    /// Resolve a cache entry for the cache benchmark field. On a hit the stored
    /// value and remaining TTL are returned; on a miss the value is generated,
    /// stored with <paramref name="ttlSeconds"/>, and returned as a non-cached
    /// entry. Synchronous wrapper so it can be called from an EntityGraphQL
    /// expression-tree field resolver (no async/await in expression trees).
    /// </summary>
    public CacheEntry GetOrSet(string key, int ttlSeconds)
    {
        var value = GetAsync(key).GetAwaiter().GetResult();
        if (value != null)
        {
            var ttl = GetTtlAsync(key).GetAwaiter().GetResult();
            return new CacheEntry
            {
                Key = key,
                Value = value,
                Cached = true,
                Ttl = ttl >= 0 ? (int)ttl : 0
            };
        }

        var generatedValue = $"value-for-{key}";
        SetAsync(key, generatedValue, ttlSeconds).GetAwaiter().GetResult();
        return new CacheEntry
        {
            Key = key,
            Value = generatedValue,
            Cached = false,
            Ttl = ttlSeconds
        };
    }

    public void Dispose()
    {
        _redis.Dispose();
    }
}
