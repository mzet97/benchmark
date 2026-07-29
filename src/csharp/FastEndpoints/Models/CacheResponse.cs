namespace BenchmarkFastEndpoints.Models;

public class CacheResponse
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public bool Cached { get; set; }
    public int Ttl { get; set; } = 300;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
