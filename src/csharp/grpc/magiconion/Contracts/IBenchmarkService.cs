using MagicOnion;

namespace MagicOnionBenchmark.Contracts;

public interface IBenchmarkService : IService<IBenchmarkService>
{
    // Scenario 1: Health check
    UnaryResult<HealthResponse> HealthAsync();

    // Scenario 2: JSON serialization (1000 objects)
    UnaryResult<JsonItemsResponse> GetJsonItemsAsync(int limit);

    // Scenario 3: Simple database query (single row)
    UnaryResult<UserResponse> GetUserAsync(int id);

    // Scenario 4: Complex database query (JOIN + aggregation)
    UnaryResult<ComplexOrdersResponse> GetComplexOrdersAsync(int days);

    // Scenario 5: Cache hit/miss
    UnaryResult<CacheResponse> GetCacheValueAsync(string key);
}
