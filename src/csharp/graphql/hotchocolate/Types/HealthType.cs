namespace GraphqlHotChocolate.Types;

public class Health
{
    public string Status { get; set; } = "";
    public string Version { get; set; } = "";
    public string Timestamp { get; set; } = "";
    public string Database { get; set; } = "";
    public string Cache { get; set; } = "";
}

public class HealthType : ObjectType<Health>
{
    protected override void Configure(IObjectTypeDescriptor<Health> descriptor)
    {
        descriptor.Name("Health");
        descriptor.Field(h => h.Status).Type<NonNullType<StringType>>();
        descriptor.Field(h => h.Version).Type<NonNullType<StringType>>();
        descriptor.Field(h => h.Timestamp).Type<NonNullType<StringType>>();
        descriptor.Field(h => h.Database).Type<NonNullType<StringType>>();
        descriptor.Field(h => h.Cache).Type<NonNullType<StringType>>();
    }
}
