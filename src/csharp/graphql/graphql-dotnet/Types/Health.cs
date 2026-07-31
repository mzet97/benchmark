using GraphQL.Types;

namespace GraphqlDotnet.Types;

public class Health
{
    public string Status { get; set; } = "";
    public string Version { get; set; } = "";
    public string Timestamp { get; set; } = "";
    public string Database { get; set; } = "";
    public string Cache { get; set; } = "";
}

public class HealthType : ObjectGraphType<Health>
{
    public HealthType()
    {
        Name = "Health";
        Field(h => h.Status).Type(new NonNullGraphType<StringGraphType>());
        Field(h => h.Version).Type(new NonNullGraphType<StringGraphType>());
        Field(h => h.Timestamp).Type(new NonNullGraphType<StringGraphType>());
        Field(h => h.Database).Type(new NonNullGraphType<StringGraphType>());
        Field(h => h.Cache).Type(new NonNullGraphType<StringGraphType>());
    }
}
