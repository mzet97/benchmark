using ProtoBuf.Grpc;
using ProtoBuf.Grpc.Configuration;

namespace ProtobufNetGrpc.Contracts;

[Service]
public interface IBenchmarkService
{
    [Operation]
    Task<HealthResponse> HealthAsync(HealthRequest request, CallContext context = default);

    [Operation]
    Task<JsonItemsResponse> GetJsonItemsAsync(JsonItemsRequest request, CallContext context = default);

    [Operation]
    Task<UserResponse> GetUserAsync(GetUserRequest request, CallContext context = default);

    [Operation]
    Task<ComplexOrdersResponse> GetComplexOrdersAsync(ComplexOrdersRequest request, CallContext context = default);

    [Operation]
    Task<CacheResponse> GetCacheValueAsync(CacheRequest request, CallContext context = default);
}
