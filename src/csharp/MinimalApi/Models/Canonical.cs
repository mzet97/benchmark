using System.Globalization;

namespace BenchmarkApi.Models;

/// <summary>
/// Canonical /json payload builder. See contracts/rest/canonical-payloads.md.
///
/// The previous implementation built 1000 items once in a static constructor
/// with Guid.NewGuid() and DateTime.UtcNow.AddDays(-i), then served the same
/// cached array for every request. That measured serialization only, while
/// every other implementation also built the items -- and it ignored ?n=
/// entirely, so the n=10/n=100/n=1000 scenarios all returned 1000 items.
/// </summary>
public static class Canonical
{
    public const int DefaultItems = 1000;
    public const int MaxItems = 10_000;
    private const string CanonicalCreatedAt = "2026-01-01T00:00:00Z";

    /// <summary>
    /// Item content is a pure function of the index: no randomness and no
    /// wall clock, so the payload is stable across runs and identical across
    /// languages.
    /// </summary>
    public static JsonItem Item(int i) => new()
    {
        Id = i,
        Uuid = $"00000000-0000-0000-0000-{i:D12}",
        Name = $"Item {i}",
        Email = $"item{i}@benchmark.local",
        CreatedAt = CanonicalCreatedAt,
        IsActive = i % 2 == 0,
    };

    /// <summary>
    /// Parse ?n=. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
    /// serialization ranking is taken at n=100.
    /// </summary>
    public static int ItemCount(string? raw)
    {
        if (string.IsNullOrEmpty(raw))
        {
            return DefaultItems;
        }

        return int.TryParse(raw, NumberStyles.None, CultureInfo.InvariantCulture, out var n)
            ? System.Math.Min(n, MaxItems)
            : DefaultItems;
    }

    public static JsonItem[] Build(int n)
    {
        var items = new JsonItem[n];
        for (var i = 0; i < n; i++)
        {
            items[i] = Item(i);
        }

        return items;
    }

    public static JsonResponse Response(string? rawCount)
    {
        var n = ItemCount(rawCount);
        return new JsonResponse
        {
            Items = Build(n),
            Count = n,
            Timestamp = System.DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ", CultureInfo.InvariantCulture),
        };
    }
}
