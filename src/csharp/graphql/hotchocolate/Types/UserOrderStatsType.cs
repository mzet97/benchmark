namespace GraphqlHotChocolate.Types;

public class UserOrderStats
{
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public int TotalOrders { get; set; }
    public double TotalValue { get; set; }
    public double AverageOrderValue { get; set; }
}

public class UserOrderStatsType : ObjectType<UserOrderStats>
{
    protected override void Configure(IObjectTypeDescriptor<UserOrderStats> descriptor)
    {
        descriptor.Name("UserOrderStats");
        descriptor.Field(s => s.UserId).Type<NonNullType<IntType>>();
        descriptor.Field(s => s.UserName).Type<NonNullType<StringType>>();
        descriptor.Field(s => s.TotalOrders).Type<NonNullType<IntType>>();
        descriptor.Field(s => s.TotalValue).Type<NonNullType<FloatType>>();
        descriptor.Field(s => s.AverageOrderValue).Type<NonNullType<FloatType>>();
    }
}

public class ComplexOrdersResult
{
    public int PeriodDays { get; set; }
    public int TotalUsers { get; set; }
    public List<UserOrderStats> Data { get; set; } = [];
}

public class ComplexOrdersResultType : ObjectType<ComplexOrdersResult>
{
    protected override void Configure(IObjectTypeDescriptor<ComplexOrdersResult> descriptor)
    {
        descriptor.Name("ComplexOrdersResult");
        descriptor.Field(r => r.PeriodDays).Type<NonNullType<IntType>>();
        descriptor.Field(r => r.TotalUsers).Type<NonNullType<IntType>>();
        descriptor.Field(r => r.Data).Type<NonNullType<ListType<NonNullType<UserOrderStatsType>>>>();
    }
}
