namespace GraphqlEntityGraphQL.Models;

public class Health
{
    public string Status { get; set; } = "";
    public string Version { get; set; } = "";
    public string Timestamp { get; set; } = "";
    public string Database { get; set; } = "";
    public string Cache { get; set; } = "";
}
