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
        var redisUrl = configuration.GetValue<string>("Redis:ConnectionString")
            ?? Environment.GetEnvironmentVariable("REDIS_URL")
            ?? throw new InvalidOperationException("Redis connection string not found");

        // Parse redis://:password@host:port to StackExchange.Redis format
        var lastAt = redisUrl.LastIndexOf('@');
        var schemeEnd = redisUrl.IndexOf("://");
        var password = redisUrl.Substring(schemeEnd + 4, lastAt - schemeEnd - 4); // skip ://:
        var hostPort = redisUrl.Substring(lastAt + 1);
        var host = hostPort.Split(':')[0];
        var port = hostPort.Contains(':') ? hostPort.Split(':')[1] : "6379";

        var redisConfig = $"{host}:{port},password={password},abortConnect=false";
        var connection = ConnectionMultiplexer.Connect(redisConfig);
        _database = connection.GetDatabase();
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
