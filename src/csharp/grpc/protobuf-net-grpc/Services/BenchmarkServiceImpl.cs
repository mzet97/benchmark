using ProtoBuf.Grpc;
using ProtobufNetGrpc.Contracts;

namespace ProtobufNetGrpc.Services;

public class BenchmarkServiceImpl : IBenchmarkService
{
    private readonly DatabaseService _database;
    private readonly CacheService _cache;
    private readonly string _version = "1.0.0";

    public BenchmarkServiceImpl(DatabaseService database, CacheService cache)
    {
        _database = database;
        _cache = cache;
    }

    public Task<HealthResponse> HealthAsync(HealthRequest request, CallContext context = default)
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

    public Task<JsonItemsResponse> GetJsonItemsAsync(JsonItemsRequest request, CallContext context = default)
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
            Items = items,
            Count = items.Count,
            Timestamp = DateTime.UtcNow.ToString("o")
        });
    }

    public async Task<UserResponse> GetUserAsync(GetUserRequest request, CallContext context = default)
    {
        return await _database.GetUserAsync(request.Id);
    }

    public async Task<ComplexOrdersResponse> GetComplexOrdersAsync(ComplexOrdersRequest request, CallContext context = default)
    {
        var days = request.Days > 0 ? request.Days : 30;
        return await _database.GetComplexOrdersAsync(days);
    }

    public async Task<CacheResponse> GetCacheValueAsync(CacheRequest request, CallContext context = default)
    {
        return await _cache.GetAsync(request.Key);
    }
}
