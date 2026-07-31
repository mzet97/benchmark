using GraphQL.Types;

namespace GraphqlDotnet.Types;

public class JsonItem
{
    public int Id { get; set; }
    public string Uuid { get; set; } = "";
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string CreatedAt { get; set; } = "";
    public bool IsActive { get; set; }
}

public class JsonItemType : ObjectGraphType<JsonItem>
{
    public JsonItemType()
    {
        Name = "JsonItem";
        Field(j => j.Id).Type(new NonNullGraphType<IntGraphType>());
        Field(j => j.Uuid).Type(new NonNullGraphType<StringGraphType>());
        Field(j => j.Name).Type(new NonNullGraphType<StringGraphType>());
        Field(j => j.Email).Type(new NonNullGraphType<StringGraphType>());
        Field(j => j.CreatedAt).Type(new NonNullGraphType<StringGraphType>());
        Field(j => j.IsActive).Type(new NonNullGraphType<BooleanGraphType>());
    }
}

public class JsonItemsResult
{
    public List<JsonItem> Items { get; set; } = [];
    public int Count { get; set; }
    public string Timestamp { get; set; } = "";
}

public class JsonItemsResultType : ObjectGraphType<JsonItemsResult>
{
    public JsonItemsResultType()
    {
        Name = "JsonItemsResult";
        Field(r => r.Items).Type(new NonNullGraphType<ListGraphType<NonNullGraphType<JsonItemType>>>());
        Field(r => r.Count).Type(new NonNullGraphType<IntGraphType>());
        Field(r => r.Timestamp).Type(new NonNullGraphType<StringGraphType>());
    }
}
