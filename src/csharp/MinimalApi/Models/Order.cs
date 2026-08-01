namespace BenchmarkApi.Models;

public class Order
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    // Navigation properties
    public User User { get; set; } = null!;
    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
}

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal Price { get; set; }
    public DateTime CreatedAt { get; set; }

    // Navigation properties
    public Order Order { get; set; } = null!;
}

public class ComplexQueryResult
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public long TotalOrders { get; set; }
    public decimal TotalValue { get; set; }
    public decimal AverageOrderValue { get; set; }
}
