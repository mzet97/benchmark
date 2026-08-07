using BenchmarkControllers.Services;
using Microsoft.AspNetCore.Mvc;

namespace BenchmarkControllers.Controllers;

[ApiController]
public class HealthController : ControllerBase
{
    private readonly IDatabaseService _databaseService;
    private readonly ICacheService _cacheService;

    public HealthController(IDatabaseService databaseService, ICacheService cacheService)
    {
        _databaseService = databaseService;
        _cacheService = cacheService;
    }

    [HttpGet("/health")]
    public async Task<IActionResult> GetHealth()
    {
        // Contract: {"status","version","timestamp","database","cache"}.
        // The previous response omitted database/cache, so it never matched.
        var dbOk = await CheckDatabaseAsync();
        var cacheOk = await CheckCacheAsync();

        return Ok(new
        {
            status = dbOk && cacheOk ? "ok" : "degraded",
            version = "1.0.0",
            timestamp = DateTime.UtcNow,
            database = dbOk ? "up" : "down",
            cache = cacheOk ? "up" : "down"
        });
    }

    private async Task<bool> CheckDatabaseAsync()
    {
        try
        {
            // GetUserByIdAsync opens a real connection; id=1 is a no-op probe
            // (it may or may not exist, but the connection succeeding is what
            // we measure).
            await _databaseService.GetUserByIdAsync(1);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private async Task<bool> CheckCacheAsync()
    {
        try
        {
            // A round-trip that exercises the connection. The value is the one
            // the cache contract reports, so this also warms the connection.
            await _cacheService.GetOrSetAsync("__healthcheck__", async () => "ok");
            return true;
        }
        catch
        {
            return false;
        }
    }

    [HttpGet("/healthz")]
    public IActionResult GetLiveness()
    {
        return Ok(new { status = "ok" });
    }

    [HttpGet("/readyz")]
    public IActionResult GetReadiness()
    {
        return Ok(new { status = "ready" });
    }
}
