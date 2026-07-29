using BenchmarkControllers.Models;
using Microsoft.AspNetCore.Mvc;

namespace BenchmarkControllers.Controllers;

[ApiController]
public class JsonController : ControllerBase
{
    private static readonly JsonItem[] CachedItems;

    static JsonController()
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

    [HttpGet("/json")]
    public IActionResult GetJson()
    {
        return Ok(new
        {
            items = CachedItems,
            count = CachedItems.Length,
            timestamp = DateTime.UtcNow
        });
    }
}
