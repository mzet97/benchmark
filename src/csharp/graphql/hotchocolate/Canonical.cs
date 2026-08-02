namespace GraphqlHotChocolate;

/// <summary>
/// Canonical /json payload contract. See contracts/rest/canonical-payloads.md.
///
/// The gRPC and GraphQL item types differ per implementation -- generated
/// protobuf classes, MagicOnion contracts, GraphQL models -- so this class
/// exposes the field values rather than a type. Each implementation builds
/// its own item from the same numbers.
///
/// Item content is a pure function of the index: no randomness and no wall
/// clock, so the payload is stable across runs and identical across
/// languages and protocols.
/// </summary>
public static class Canonical
{
    public const int DefaultItems = 1000;
    public const int MaxItems = 10_000;

    /// <summary>
    /// Fixed by the contract. Formatting the clock once per item is work no
    /// implementation should be timed on.
    /// </summary>
    public const string CreatedAt = "2026-01-01T00:00:00Z";

    public static string Uuid(int i) => $"00000000-0000-0000-0000-{i:D12}";

    public static string Name(int i) => $"Item {i}";

    public static string Email(int i) => $"item{i}@benchmark.local";

    public static bool IsActive(int i) => i % 2 == 0;

    /// <summary>
    /// Clamp the requested limit. On a 1 GbE link 1000 items is
    /// network-bound, so the serialization ranking is taken at 100.
    /// </summary>
    public static int ItemCount(int? limit)
    {
        if (limit is not int n || n <= 0)
        {
            return DefaultItems;
        }

        return n > MaxItems ? MaxItems : n;
    }
}
