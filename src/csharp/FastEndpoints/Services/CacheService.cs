using StackExchange.Redis;

namespace BenchmarkFastEndpoints.Services;

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
        var redisUrl = configuration.GetValue<string>("Redis:ConnectionString")
            ?? Environment.GetEnvironmentVariable("REDIS_URL")
            ?? "redis:6379";

        // Simple parsing: handle redis://host:port or just host:port
        string host, port, password;
        if (redisUrl.StartsWith("redis://"))
        {
            var afterScheme = redisUrl.Substring("redis://".Length);
            var lastAt = afterScheme.LastIndexOf('@');
            if (lastAt >= 0)
            {
                password = afterScheme.Substring(0, lastAt).TrimStart(':');
                var hostPort = afterScheme.Substring(lastAt + 1);
                var parts = hostPort.Split(':');
                host = parts[0];
                port = parts.Length > 1 ? parts[1] : "6379";
            }
            else
            {
                password = "";
                var parts = afterScheme.Split(':');
                host = parts[0];
                port = parts.Length > 1 ? parts[1] : "6379";
            }
        }
        else
        {
            password = "";
            var parts = redisUrl.Split(':');
            host = parts[0];
            port = parts.Length > 1 ? parts[1] : "6379";
        }

        var redisConfig = string.IsNullOrEmpty(password)
            ? $"{host}:{port},abortConnect=false"
            : $"{host}:{port},password={password},abortConnect=false";
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
