using BenchmarkControllers.Services;
using Microsoft.AspNetCore.Mvc;

namespace BenchmarkControllers.Controllers;

[ApiController]
public class CacheController : ControllerBase
{
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

        var value = await _cacheService.GetOrSetAsync(key, async () =>
        {
            await Task.Delay(50); // Simulate some work
            return $"Cached value for {key} at {DateTime.UtcNow:O}";
        });

        return Ok(new
        {
            key,
            value,
            cached = value.Contains("Cached value"),
            ttl = 300,
            timestamp = DateTime.UtcNow
        });
    }
}
