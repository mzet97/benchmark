using BenchmarkFastEndpoints.Services;
using FastEndpoints;

namespace BenchmarkFastEndpoints.Endpoints;

public class CacheRequest
{
    public string? Key { get; set; }
}

public class CacheEndpoint : Endpoint<CacheRequest>
{
    // The TTL is part of the response contract and must match the expiry the
    // cache service writes. See contracts/rest/canonical-payloads.md.
    private const int CacheTtlSeconds = 300;

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
    }

    public override async Task HandleAsync(CacheRequest req, CancellationToken ct)
    {
        if (string.IsNullOrEmpty(req.Key))
        {
            await SendAsync(new { error = "Key parameter is required" }, 400, cancellation: ct);
            return;
        }

        _logger.LogInformation("Cache request for key: {Key}", req.Key);

        var (value, cached) = await _cacheService.GetOrSetAsync(req.Key, async () =>
        {
            return $"Cached value for {req.Key} at {DateTime.UtcNow:O}";
        });

        await SendAsync(new
        {
            key = req.Key,
            value,
            cached,
            ttl = CacheTtlSeconds,
            timestamp = DateTime.UtcNow
        }, cancellation: ct);
    }
}
