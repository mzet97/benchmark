using StackExchange.Redis;

namespace BenchmarkApi.Services;

public interface ICacheService
{
    Task<string?> GetAsync(string key);
    Task SetAsync(string key, string value, TimeSpan expiry);
    Task<string> GetOrSetAsync(string key, Func<Task<string>> factory);
}

public class CacheService : ICacheService
{
    private readonly IDatabase _database;
    private readonly TimeSpan _defaultExpiry = TimeSpan.FromMinutes(5);

    public CacheService(IConfiguration configuration)
    {
        var redisConnectionString = configuration.GetValue<string>("Redis:ConnectionString")
            ?? throw new InvalidOperationException("Redis connection string not found");

        var connection = ConnectionMultiplexer.Connect(redisConnectionString);
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

    public async Task<string> GetOrSetAsync(string key, Func<Task<string>> factory)
    {
        var cachedValue = await GetAsync(key);
        if (cachedValue != null)
        {
            return cachedValue;
        }

        var value = await factory();
        await SetAsync(key, value, _defaultExpiry);
        return value;
    }
}
