namespace GraphqlEntityGraphQL.Models;

public class JsonItem
{
    public int Id { get; set; }
    public string Uuid { get; set; } = "";
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string CreatedAt { get; set; } = "";
    public bool IsActive { get; set; }
}

public class JsonItemsResult
{
    public List<JsonItem> Items { get; set; } = [];
    public int Count { get; set; }
    public string Timestamp { get; set; } = "";
}
