namespace GraphqlHotChocolate.Types;

public class CacheEntry
{
    public string Key { get; set; } = "";
    public string Value { get; set; } = "";
    public bool Cached { get; set; }
    public int Ttl { get; set; }
}

public class CacheEntryType : ObjectType<CacheEntry>
{
    protected override void Configure(IObjectTypeDescriptor<CacheEntry> descriptor)
    {
        descriptor.Name("CacheEntry");
        descriptor.Field(c => c.Key).Type<NonNullType<StringType>>();
        descriptor.Field(c => c.Value).Type<NonNullType<StringType>>();
        descriptor.Field(c => c.Cached).Type<NonNullType<BooleanType>>();
        descriptor.Field(c => c.Ttl).Type<NonNullType<IntType>>();
    }
}
