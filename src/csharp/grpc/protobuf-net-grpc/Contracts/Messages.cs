using ProtoBuf;

namespace ProtobufNetGrpc.Contracts;

[ProtoContract]
public class HealthRequest
{
}

[ProtoContract]
public class HealthResponse
{
    [ProtoMember(1)]
    public string Status { get; set; } = "";

    [ProtoMember(2)]
    public string Version { get; set; } = "";

    [ProtoMember(3)]
    public string Timestamp { get; set; } = "";

    [ProtoMember(4)]
    public string Database { get; set; } = "";

    [ProtoMember(5)]
    public string Cache { get; set; } = "";
}

[ProtoContract]
public class JsonItemsRequest
{
    [ProtoMember(1)]
    public int Limit { get; set; }
}

[ProtoContract]
public class JsonItemsResponse
{
    [ProtoMember(1)]
    public List<JsonItem> Items { get; set; } = new();

    [ProtoMember(2)]
    public int Count { get; set; }

    [ProtoMember(3)]
    public string Timestamp { get; set; } = "";
}

[ProtoContract]
public class JsonItem
{
    [ProtoMember(1)]
    public int Id { get; set; }

    [ProtoMember(2)]
    public string Uuid { get; set; } = "";

    [ProtoMember(3)]
    public string Name { get; set; } = "";

    [ProtoMember(4)]
    public string Email { get; set; } = "";

    [ProtoMember(5)]
    public string CreatedAt { get; set; } = "";

    [ProtoMember(6)]
    public bool IsActive { get; set; }
}

[ProtoContract]
public class GetUserRequest
{
    [ProtoMember(1)]
    public int Id { get; set; }
}

[ProtoContract]
public class UserResponse
{
    [ProtoMember(1)]
    public int Id { get; set; }

    [ProtoMember(2)]
    public string Email { get; set; } = "";

    [ProtoMember(3)]
    public string FirstName { get; set; } = "";

    [ProtoMember(4)]
    public string LastName { get; set; } = "";

    [ProtoMember(5)]
    public int Age { get; set; }

    [ProtoMember(6)]
    public string CreatedAt { get; set; } = "";
}

[ProtoContract]
public class ComplexOrdersRequest
{
    [ProtoMember(1)]
    public int Days { get; set; }
}

[ProtoContract]
public class ComplexOrdersResponse
{
    [ProtoMember(1)]
    public int PeriodDays { get; set; }

    [ProtoMember(2)]
    public int TotalUsers { get; set; }

    [ProtoMember(3)]
    public List<UserOrderStats> Data { get; set; } = new();
}

[ProtoContract]
public class UserOrderStats
{
    [ProtoMember(1)]
    public int UserId { get; set; }

    [ProtoMember(2)]
    public string UserName { get; set; } = "";

    [ProtoMember(3)]
    public int TotalOrders { get; set; }

    [ProtoMember(4)]
    public double TotalValue { get; set; }

    [ProtoMember(5)]
    public double AverageOrderValue { get; set; }
}

[ProtoContract]
public class CacheRequest
{
    [ProtoMember(1)]
    public string Key { get; set; } = "";
}

[ProtoContract]
public class CacheResponse
{
    [ProtoMember(1)]
    public string Key { get; set; } = "";

    [ProtoMember(2)]
    public string Value { get; set; } = "";

    [ProtoMember(3)]
    public bool Cached { get; set; }

    [ProtoMember(4)]
    public int Ttl { get; set; }

    [ProtoMember(5)]
    public string Timestamp { get; set; } = "";
}
