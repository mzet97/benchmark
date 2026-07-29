namespace BenchmarkControllers.Models;

public class ComplexResult
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public int TotalOrders { get; set; }
    public decimal TotalValue { get; set; }
    public decimal AverageOrderValue { get; set; }
}
