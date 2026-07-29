using MessagePack;

namespace MagicOnionBenchmark.Contracts;

[MessagePackObject(true)]
public class HealthResponse
{
    public string Status { get; set; } = "";
    public string Version { get; set; } = "";
    public string Timestamp { get; set; } = "";
    public string Database { get; set; } = "";
    public string Cache { get; set; } = "";
}

[MessagePackObject(true)]
public class JsonItemsResponse
{
    public List<JsonItem> Items { get; set; } = new();
    public int Count { get; set; }
    public string Timestamp { get; set; } = "";
}

[MessagePackObject(true)]
public class JsonItem
{
    public int Id { get; set; }
    public string Uuid { get; set; } = "";
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string CreatedAt { get; set; } = "";
    public bool IsActive { get; set; }
}

[MessagePackObject(true)]
public class UserResponse
{
    public int Id { get; set; }
    public string Email { get; set; } = "";
    public string FirstName { get; set; } = "";
    public string LastName { get; set; } = "";
    public int Age { get; set; }
    public string CreatedAt { get; set; } = "";
}

[MessagePackObject(true)]
public class ComplexOrdersResponse
{
    public int PeriodDays { get; set; }
    public int TotalUsers { get; set; }
    public List<UserOrderStats> Data { get; set; } = new();
}

[MessagePackObject(true)]
public class UserOrderStats
{
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public int TotalOrders { get; set; }
    public double TotalValue { get; set; }
    public double AverageOrderValue { get; set; }
}

[MessagePackObject(true)]
public class CacheResponse
{
    public string Key { get; set; } = "";
    public string Value { get; set; } = "";
    public bool Cached { get; set; }
    public int Ttl { get; set; }
    public string Timestamp { get; set; } = "";
}
