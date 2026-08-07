using BenchmarkFastEndpoints.Services;
using FastEndpoints;

namespace BenchmarkFastEndpoints.Endpoints;

public class HealthEndpoint : EndpointWithoutRequest
{
    private readonly IDatabaseService _databaseService;
    private readonly ICacheService _cacheService;

    public HealthEndpoint(IDatabaseService databaseService, ICacheService cacheService)
    {
        _databaseService = databaseService;
        _cacheService = cacheService;
    }

    public override void Configure()
    {
        Get("/health");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        // Contract: {"status","version","timestamp","database","cache"}.
        // The previous response omitted database/cache, so it never matched.
        var dbOk = await CheckDatabaseAsync();
        var cacheOk = await CheckCacheAsync();

        await SendAsync(new
        {
            status = dbOk && cacheOk ? "ok" : "degraded",
            version = "1.0.0",
            timestamp = DateTime.UtcNow,
            database = dbOk ? "up" : "down",
            cache = cacheOk ? "up" : "down"
        }, cancellation: ct);
    }

    private async Task<bool> CheckDatabaseAsync()
    {
        try
        {
            // GetUserByIdAsync opens a real connection; the probe id does not
            // need to exist -- the connection succeeding is what we measure.
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
            // A round-trip that exercises the Redis connection.
            await _cacheService.GetOrSetAsync("__healthcheck__", async () => "ok");
            return true;
        }
        catch
        {
            return false;
        }
    }
}

public class LivenessEndpoint : EndpointWithoutRequest
{
    public override void Configure()
    {
        Get("/healthz");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        await SendAsync(new { status = "ok" }, cancellation: ct);
    }
}

public class ReadinessEndpoint : EndpointWithoutRequest
{
    public override void Configure()
    {
        Get("/readyz");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        await SendAsync(new { status = "ready" }, cancellation: ct);
    }
}
