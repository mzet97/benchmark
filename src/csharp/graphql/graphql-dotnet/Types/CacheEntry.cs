using GraphQL.Types;

namespace GraphqlDotnet.Types;

public class CacheEntry
{
    public string Key { get; set; } = "";
    public string Value { get; set; } = "";
    public bool Cached { get; set; }
    public int Ttl { get; set; }
}

public class CacheEntryType : ObjectGraphType<CacheEntry>
{
    public CacheEntryType()
    {
        Name = "CacheEntry";
        Field(c => c.Key).Type(new NonNullGraphType<StringGraphType>());
        Field(c => c.Value).Type(new NonNullGraphType<StringGraphType>());
        Field(c => c.Cached).Type(new NonNullGraphType<BooleanGraphType>());
        Field(c => c.Ttl).Type(new NonNullGraphType<IntGraphType>());
    }
}
