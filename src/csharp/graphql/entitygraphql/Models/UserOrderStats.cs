namespace GraphqlEntityGraphQL.Models;

public class UserOrderStats
{
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public int TotalOrders { get; set; }
    public double TotalValue { get; set; }
    public double AverageOrderValue { get; set; }
}

public class ComplexOrdersResult
{
    public int PeriodDays { get; set; }
    public int TotalUsers { get; set; }
    public List<UserOrderStats> Data { get; set; } = [];
}
