using GraphQL.Types;

namespace GraphqlDotnet.Types;

public class UserOrderStats
{
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public int TotalOrders { get; set; }
    public double TotalValue { get; set; }
    public double AverageOrderValue { get; set; }
}

public class UserOrderStatsType : ObjectGraphType<UserOrderStats>
{
    public UserOrderStatsType()
    {
        Name = "UserOrderStats";
        Field(s => s.UserId).Type<NonNullGraphType<IntGraphType>>();
        Field(s => s.UserName).Type<NonNullGraphType<StringGraphType>>();
        Field(s => s.TotalOrders).Type<NonNullGraphType<IntGraphType>>();
        Field(s => s.TotalValue).Type<NonNullGraphType<FloatGraphType>>();
        Field(s => s.AverageOrderValue).Type<NonNullGraphType<FloatGraphType>>();
    }
}

public class ComplexOrdersResult
{
    public int PeriodDays { get; set; }
    public int TotalUsers { get; set; }
    public List<UserOrderStats> Data { get; set; } = [];
}

public class ComplexOrdersResultType : ObjectGraphType<ComplexOrdersResult>
{
    public ComplexOrdersResultType()
    {
        Name = "ComplexOrdersResult";
        Field(r => r.PeriodDays).Type<NonNullGraphType<IntGraphType>>();
        Field(r => r.TotalUsers).Type<NonNullGraphType<IntGraphType>>();
        Field(r => r.Data).Type<NonNullGraphType<ListGraphType<NonNullGraphType<UserOrderStatsType>>>>();
    }
}
