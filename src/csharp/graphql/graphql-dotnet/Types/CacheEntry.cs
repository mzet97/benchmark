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
        Field(c => c.Key).Type<NonNullGraphType<StringGraphType>>();
        Field(c => c.Value).Type<NonNullGraphType<StringGraphType>>();
        Field(c => c.Cached).Type<NonNullGraphType<BooleanGraphType>>();
        Field(c => c.Ttl).Type<NonNullGraphType<IntGraphType>>();
    }
}
