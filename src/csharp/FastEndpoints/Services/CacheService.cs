using StackExchange.Redis;

namespace BenchmarkFastEndpoints.Services;

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
        // Build the connection from the component ConfigMap variables
        // (REDIS_HOST/REDIS_PORT/REDIS_PASSWORD). REDIS_URL is percent-encoded
        // (redis://:Admin%40123@host:6379) and neither Uri.UserInfo nor the
        // earlier hand-rolled parser decoded "%40" -> "@", so the literal
        // "Admin%40123" was sent to Redis and auth failed -- cache:down.
        // Reading the already-decoded REDIS_PASSWORD sidesteps URL parsing.
        var host = Environment.GetEnvironmentVariable("REDIS_HOST");
        var port = Environment.GetEnvironmentVariable("REDIS_PORT") ?? "6379";
        var password = Environment.GetEnvironmentVariable("REDIS_PASSWORD");

        string redisConfig;
        if (!string.IsNullOrEmpty(host))
        {
            redisConfig = string.IsNullOrEmpty(password)
                ? $"{host}:{port},abortConnect=false"
                : $"{host}:{port},password={password},abortConnect=false";
        }
        else
        {
            // Fall back to a configured connection string / REDIS_URL for local dev.
            redisConfig = configuration.GetValue<string>("Redis:ConnectionString")
                ?? Environment.GetEnvironmentVariable("REDIS_URL")
                ?? "redis:6379,abortConnect=false";
        }

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
