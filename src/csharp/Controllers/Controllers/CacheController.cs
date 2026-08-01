using BenchmarkControllers.Services;
using Microsoft.AspNetCore.Mvc;

namespace BenchmarkControllers.Controllers;

[ApiController]
public class CacheController : ControllerBase
{
    // The TTL is part of the response contract and must match the expiry the
    // cache service writes. See contracts/rest/canonical-payloads.md.
    private const int CacheTtlSeconds = 300;

    private readonly ICacheService _cacheService;
    private readonly ILogger<CacheController> _logger;

    public CacheController(ICacheService cacheService, ILogger<CacheController> logger)
    {
        _cacheService = cacheService;
        _logger = logger;
    }

    [HttpGet("/cache")]
    public async Task<IActionResult> GetCache([FromQuery] string? key)
    {
        if (string.IsNullOrEmpty(key))
        {
            return BadRequest(new { error = "Key parameter is required" });
        }

        _logger.LogInformation("Cache request for key: {Key}", key);

        var (value, cached) = await _cacheService.GetOrSetAsync(key, async () =>
        {
            return $"Cached value for {key} at {DateTime.UtcNow:O}";
        });

        return Ok(new
        {
            key,
            value,
            cached,
            ttl = CacheTtlSeconds,
            timestamp = DateTime.UtcNow
        });
    }
}
