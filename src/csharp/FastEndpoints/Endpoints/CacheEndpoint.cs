using BenchmarkFastEndpoints.Services;
using FastEndpoints;

namespace BenchmarkFastEndpoints.Endpoints;

public class CacheRequest
{
    public string? Key { get; set; }
}

public class CacheEndpoint : Endpoint<CacheRequest>
{
    private readonly ICacheService _cacheService;
    private readonly ILogger<CacheEndpoint> _logger;

    public CacheEndpoint(ICacheService cacheService, ILogger<CacheEndpoint> logger)
    {
        _cacheService = cacheService;
        _logger = logger;
    }

    public override void Configure()
    {
        Get("/cache");
        AllowAnonymous();
        Params<CacheRequest>();
    }

    public override async Task HandleAsync(CacheRequest req, CancellationToken ct)
    {
        if (string.IsNullOrEmpty(req.Key))
        {
            await SendAsync(new { error = "Key parameter is required" }, 400, cancellation: ct);
            return;
        }

        _logger.LogInformation("Cache request for key: {Key}", req.Key);

        var value = await _cacheService.GetOrSetAsync(req.Key, async () =>
        {
            await Task.Delay(50, ct); // Simulate some work
            return $"Cached value for {req.Key} at {DateTime.UtcNow:O}";
        });

        await SendAsync(new
        {
            key = req.Key,
            value,
            cached = value.Contains("Cached value"),
            ttl = 300,
            timestamp = DateTime.UtcNow
        }, cancellation: ct);
    }
}
