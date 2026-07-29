using StackExchange.Redis;
using MagicOnionBenchmark.Contracts;

namespace MagicOnionBenchmark.Services;

public class CacheService : IDisposable
{
    private readonly ConnectionMultiplexer _redis;
    private readonly IDatabase _db;

    public CacheService(IConfiguration configuration)
    {
        var connectionString = configuration.GetValue<string>("ConnectionStrings:Redis")
            ?? Environment.GetEnvironmentVariable("REDIS_URL")
            ?? "localhost:6379";

        _redis = ConnectionMultiplexer.Connect(connectionString);
        _db = _redis.GetDatabase();
    }

    public async Task<CacheResponse> GetAsync(string key)
    {
        var value = await _db.StringGetAsync(key);
        var ttl = await _db.KeyTimeToLiveAsync(key);

        if (value.HasValue)
        {
            return new CacheResponse
            {
                Key = key,
                Value = value.ToString(),
                Cached = true,
                Ttl = (int)(ttl?.TotalSeconds ?? 0),
                Timestamp = DateTime.UtcNow.ToString("o")
            };
        }

        // Cache miss - generate value and store it
        var generatedValue = $"value-{Guid.NewGuid()}";
        await _db.StringSetAsync(key, generatedValue, TimeSpan.FromMinutes(5));

        return new CacheResponse
        {
            Key = key,
            Value = generatedValue,
            Cached = false,
            Ttl = 300,
            Timestamp = DateTime.UtcNow.ToString("o")
        };
    }

    public void Dispose()
    {
        _redis?.Dispose();
    }
}
