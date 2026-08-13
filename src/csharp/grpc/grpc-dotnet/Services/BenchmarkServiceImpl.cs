using Grpc.Core;
using Benchmark;
using GrpcDotnet;

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

    // Database and Cache were the literals "connected", with no I/O of any kind, so
    // this RPC reported health it had never checked -- invariante 6 in
    // docs/ACTION_PLAN.md, an implementation that does not implement. The Rust
    // tonic sibling pings both for this same RPC.
    public override async Task<HealthResponse> Health(HealthRequest request, ServerCallContext context)
    {
        var dbOk = await _database.PingAsync();
        var cacheOk = await _cache.PingAsync();

        return new HealthResponse
        {
            Status = dbOk && cacheOk ? "ok" : "degraded",
            Version = _version,
            Timestamp = DateTime.UtcNow.ToString("o"),
            Database = dbOk ? "connected" : "disconnected",
            Cache = cacheOk ? "connected" : "disconnected"
        };
    }

    public override Task<JsonItemsResponse> GetJsonItems(JsonItemsRequest request, ServerCallContext context)
    {
        var count = Canonical.ItemCount(request.Limit);
        var items = new List<JsonItem>();

        for (int i = 0; i < count; i++)
        {
            items.Add(new JsonItem
            {
                Id = i,
                Uuid = Canonical.Uuid(i),
                Name = Canonical.Name(i),
                Email = Canonical.Email(i),
                CreatedAt = Canonical.CreatedAt,
                IsActive = Canonical.IsActive(i)
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
