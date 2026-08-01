using BenchmarkApi.Services;

namespace BenchmarkApi.Handlers;

public static class CacheHandler
{
    // The TTL is part of the response contract and must match the expiry the
    // cache service writes. See contracts/rest/canonical-payloads.md.
    private const int CacheTtlSeconds = 300;

    public static async Task<IResult> GetCacheAsync(
        string? key,
        ICacheService cacheService,
        ILogger logger)
    {
        if (string.IsNullOrEmpty(key))
        {
            return Results.BadRequest(new { error = "Key parameter is required" });
        }

        logger.LogInformation("Cache request for key: {Key}", key);

        var (value, cached) = await cacheService.GetOrSetAsync(key, async () =>
        {
            return $"Cached value for {key} at {DateTime.UtcNow:O}";
        });

        return Results.Ok(new
        {
            key,
            value,
            cached,
            ttl = CacheTtlSeconds,
            timestamp = DateTime.UtcNow
        });
    }
}
