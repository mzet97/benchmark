using GraphQL.Types;
using GraphqlDotnet.Types;

namespace GraphqlDotnet.Schema;

public class BenchmarkSchema : GraphQL.Types.Schema
{
    public BenchmarkSchema(IServiceProvider serviceProvider) : base(serviceProvider)
    {
        Query = serviceProvider.GetRequiredService<QueryType>();
    }
}
