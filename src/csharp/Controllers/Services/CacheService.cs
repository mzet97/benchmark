using StackExchange.Redis;

namespace BenchmarkControllers.Services;

public interface ICacheService
{
    Task<string?> GetAsync(string key);
    Task SetAsync(string key, string value, TimeSpan expiry);
    // Returns the value and whether it came from Redis. The endpoints used to
    // infer that with value.Contains("Cached value"), which is true exactly
    // when the value was just generated -- the flag reported the opposite of
    // what happened.
    Task<(string Value, bool Cached)> GetOrSetAsync(string key, Func<Task<string>> factory);
}

public class CacheService : ICacheService
{
    private readonly IDatabase _database;
    private readonly TimeSpan _defaultExpiry = TimeSpan.FromMinutes(5);

    public CacheService(IConfiguration configuration)
    {
        // Prefer the connection string Program.cs already built. REDIS_URL is
        // percent-encoded and the previous hand-rolled parser passed the raw
        // encoded password to Redis.
        var configured = configuration.GetValue<string>("Redis:ConnectionString");
        if (!string.IsNullOrEmpty(configured))
        {
            var connection = ConnectionMultiplexer.Connect(configured);
            _database = connection.GetDatabase();
            return;
        }

        var redisUrl = Environment.GetEnvironmentVariable("REDIS_URL")
            ?? throw new InvalidOperationException("Redis connection string not found");

        // Parse redis://:password@host:port using Uri, which decodes the
        // percent-encoded password correctly.
        var uri = new Uri(redisUrl);
        var password = uri.UserInfo;
        if (uri.UserInfo.Contains(':'))
        {
            password = uri.UserInfo.Substring(uri.UserInfo.IndexOf(':') + 1);
        }
        var host = uri.Host;
        var port = uri.Port != 0 ? uri.Port : 6379;

        var redisConfig = $"{host}:{port},password={password},abortConnect=false";
        var conn = ConnectionMultiplexer.Connect(redisConfig);
        _database = conn.GetDatabase();
    }

    public async Task<string?> GetAsync(string key)
    {
        return await _database.StringGetAsync(key);
    }

    public async Task SetAsync(string key, string value, TimeSpan expiry)
    {
        await _database.StringSetAsync(key, value, expiry);
    }

    public async Task<(string Value, bool Cached)> GetOrSetAsync(string key, Func<Task<string>> factory)
    {
        var cachedValue = await GetAsync(key);
        if (cachedValue != null)
        {
            return (cachedValue, true);
        }

        var value = await factory();
        await SetAsync(key, value, _defaultExpiry);
        return (value, false);
    }
}
