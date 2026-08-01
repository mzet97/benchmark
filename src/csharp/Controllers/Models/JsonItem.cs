using System.Text.Json.Serialization;

namespace BenchmarkControllers.Models;

/// <summary>
/// Canonical /json item. See contracts/rest/canonical-payloads.md.
///
/// The shape matches JsonItem in contracts/grpc/benchmark.proto and
/// type JsonItem in contracts/graphql/schema.graphql, so all three protocols
/// serialize the same data.
///
/// CreatedAt is a string, not a DateTime: the contract pins the exact wire
/// value and every runtime formats DateTime a little differently. The
/// [JsonPropertyName] attributes pin the wire names so the payload does not
/// depend on whichever naming policy the host happens to apply.
/// </summary>
public sealed class JsonItem
{
    [JsonPropertyName("id")]
    public int Id { get; init; }

    [JsonPropertyName("uuid")]
    public string Uuid { get; init; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; init; } = string.Empty;

    [JsonPropertyName("email")]
    public string Email { get; init; } = string.Empty;

    [JsonPropertyName("createdAt")]
    public string CreatedAt { get; init; } = string.Empty;

    [JsonPropertyName("isActive")]
    public bool IsActive { get; init; }
}

/// <summary>
/// Envelope for /json. Timestamp is the only clock-dependent field and is
/// excluded from the parity hash.
/// </summary>
public sealed class JsonResponse
{
    [JsonPropertyName("items")]
    public JsonItem[] Items { get; init; } = System.Array.Empty<JsonItem>();

    [JsonPropertyName("count")]
    public int Count { get; init; }

    [JsonPropertyName("timestamp")]
    public string Timestamp { get; init; } = string.Empty;
}
