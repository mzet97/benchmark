namespace BenchmarkControllers.Models;

// Mirrors UserOrderStats in contracts/grpc/benchmark.proto.
// See contracts/rest/canonical-payloads.md.
public class ComplexResult
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public long TotalOrders { get; set; }
    public decimal TotalValue { get; set; }
    public decimal AverageOrderValue { get; set; }
}
