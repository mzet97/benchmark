using Grpc.Core;
using Benchmark;

namespace GrpcDotnet.Services;

public class BenchmarkServiceImpl : BenchmarkService.BenchmarkServiceBase
{
    private readonly DatabaseService _database;
    private readonly CacheService _cache;
    private readonly string _version = "1.0.0";

    public BenchmarkServiceImpl(DatabaseService database, CacheService cache)
    {
        _database = database;
        _cache = cache;
    }

    public override Task<HealthResponse> Health(HealthRequest request, ServerCallContext context)
    {
        return Task.FromResult(new HealthResponse
        {
            Status = "ok",
            Version = _version,
            Timestamp = DateTime.UtcNow.ToString("o"),
            Database = "connected",
            Cache = "connected"
        });
    }

    public override Task<JsonItemsResponse> GetJsonItems(JsonItemsRequest request, ServerCallContext context)
    {
        var limit = request.Limit > 0 ? request.Limit : 1000;
        var items = new List<JsonItem>();

        for (int i = 0; i < limit; i++)
        {
            items.Add(new JsonItem
            {
                Id = i,
                Uuid = Guid.NewGuid().ToString(),
                Name = $"User_{i}",
                Email = $"user{i}@example.com",
                CreatedAt = DateTime.UtcNow.ToString("o"),
                IsActive = i % 2 == 0
            });
        }

        return Task.FromResult(new JsonItemsResponse
        {
            Items = { items },
            Count = items.Count,
            Timestamp = DateTime.UtcNow.ToString("o")
        });
    }

    public override async Task<UserResponse> GetUser(GetUserRequest request, ServerCallContext context)
    {
        return await _database.GetUserAsync(request.Id);
    }

    public override async Task<ComplexOrdersResponse> GetComplexOrders(ComplexOrdersRequest request, ServerCallContext context)
    {
        var days = request.Days > 0 ? request.Days : 30;
        return await _database.GetComplexOrdersAsync(days);
    }

    public override async Task<CacheResponse> GetCacheValue(CacheRequest request, ServerCallContext context)
    {
        return await _cache.GetAsync(request.Key);
    }
}
