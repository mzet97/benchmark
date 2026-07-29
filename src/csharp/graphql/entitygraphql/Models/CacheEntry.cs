namespace GraphqlEntityGraphQL.Models;

public class CacheEntry
{
    public string Key { get; set; } = "";
    public string Value { get; set; } = "";
    public bool Cached { get; set; }
    public int Ttl { get; set; }
}
