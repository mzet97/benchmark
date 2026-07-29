using FastEndpoints;

namespace BenchmarkFastEndpoints.Endpoints;

public class HealthEndpoint : EndpointWithoutRequest
{
    public override void Configure()
    {
        Get("/health");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        await SendAsync(new { status = "ok", timestamp = DateTime.UtcNow }, cancellation: ct);
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
