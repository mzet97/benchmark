namespace GraphqlHotChocolate.Types;

public class JsonItem
{
    public int Id { get; set; }
    public string Uuid { get; set; } = "";
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string CreatedAt { get; set; } = "";
    public bool IsActive { get; set; }
}

public class JsonItemType : ObjectType<JsonItem>
{
    protected override void Configure(IObjectTypeDescriptor<JsonItem> descriptor)
    {
        descriptor.Name("JsonItem");
        descriptor.Field(j => j.Id).Type<NonNullType<IntType>>();
        descriptor.Field(j => j.Uuid).Type<NonNullType<StringType>>();
        descriptor.Field(j => j.Name).Type<NonNullType<StringType>>();
        descriptor.Field(j => j.Email).Type<NonNullType<StringType>>();
        descriptor.Field(j => j.CreatedAt).Type<NonNullType<StringType>>();
        descriptor.Field(j => j.IsActive).Type<NonNullType<BooleanType>>();
    }
}

public class JsonItemsResult
{
    public List<JsonItem> Items { get; set; } = [];
    public int Count { get; set; }
    public string Timestamp { get; set; } = "";
}

public class JsonItemsResultType : ObjectType<JsonItemsResult>
{
    protected override void Configure(IObjectTypeDescriptor<JsonItemsResult> descriptor)
    {
        descriptor.Name("JsonItemsResult");
        descriptor.Field(r => r.Items).Type<NonNullType<ListType<NonNullType<JsonItemType>>>>();
        descriptor.Field(r => r.Count).Type<NonNullType<IntType>>();
        descriptor.Field(r => r.Timestamp).Type<NonNullType<StringType>>();
    }
}
