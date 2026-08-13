using ProtoBuf.Grpc;
using ProtobufNetGrpc.Contracts;
using ProtobufNetGrpc;

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

    // Database and Cache were the literals "connected", with no I/O of any kind, so
    // this RPC reported health it had never checked -- invariante 6 in
    // docs/ACTION_PLAN.md, an implementation that does not implement. The Rust
    // tonic sibling pings both for this same RPC.
    public async Task<HealthResponse> HealthAsync(HealthRequest request, CallContext context = default)
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

    public Task<JsonItemsResponse> GetJsonItemsAsync(JsonItemsRequest request, CallContext context = default)
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
