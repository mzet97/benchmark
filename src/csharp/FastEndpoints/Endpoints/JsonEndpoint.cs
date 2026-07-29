using BenchmarkFastEndpoints.Models;
using FastEndpoints;

namespace BenchmarkFastEndpoints.Endpoints;

public class JsonEndpoint : EndpointWithoutRequest
{
    private static readonly JsonItem[] CachedItems;

    static JsonEndpoint()
    {
        var items = new List<JsonItem>(1000);
        for (int i = 1; i <= 1000; i++)
        {
            items.Add(new JsonItem
            {
                Id = i,
                Uuid = Guid.NewGuid().ToString(),
                Name = $"User {i}",
                Email = $"user{i}@example.com",
                CreatedAt = DateTime.UtcNow.AddDays(-i),
                IsActive = i % 2 == 0
            });
        }
        CachedItems = items.ToArray();
    }

    public override void Configure()
    {
        Get("/json");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        await SendAsync(new
        {
            items = CachedItems,
            count = CachedItems.Length,
            timestamp = DateTime.UtcNow
        }, cancellation: ct);
    }
}
