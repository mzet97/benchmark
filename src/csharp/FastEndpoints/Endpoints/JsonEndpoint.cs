using BenchmarkFastEndpoints.Models;
using FastEndpoints;

namespace BenchmarkFastEndpoints.Endpoints;

public class JsonEndpoint : EndpointWithoutRequest
{
    public override void Configure()
    {
        Get("/json");
        AllowAnonymous();
    }

    public override Task HandleAsync(CancellationToken ct)
    {
        return SendAsync(Canonical.Response(Query<string?>("n", isRequired: false)), cancellation: ct);
    }
}
