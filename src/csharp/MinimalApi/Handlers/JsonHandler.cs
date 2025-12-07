using BenchmarkApi.Models;

namespace BenchmarkApi.Handlers;

public static class JsonHandler
{
    private static readonly JsonItem[]? CachedItems;

    static JsonHandler()
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

    public static IResult GetJson()
    {
        return Results.Ok(new { items = CachedItems });
    }
}
