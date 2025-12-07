using BenchmarkApi.Services;

namespace BenchmarkApi.Handlers;

public static class CacheHandler
{
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

        var value = await cacheService.GetOrSetAsync(key, async () =>
        {
            await Task.Delay(50); // Simulate some work
            return $"Cached value for {key} at {DateTime.UtcNow:O}";
        });

        return Results.Ok(new
        {
            key,
            value,
            cached = value.Contains("Cached value"),
            timestamp = DateTime.UtcNow
        });
    }
}
