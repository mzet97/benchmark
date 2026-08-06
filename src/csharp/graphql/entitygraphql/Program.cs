using EntityGraphQL.AspNet;
using EntityGraphQL.Schema;
using GraphqlEntityGraphQL.Services;
using GraphqlEntityGraphQL.Schema;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<DatabaseService>();
builder.Services.AddSingleton<CacheService>();
// EntityGraphQL resolves the query context object from the request service
// provider, so BenchmarkContext must be registered.
builder.Services.AddSingleton<BenchmarkContext>();

// Let EntityGraphQL.AspNet register the GraphQL infrastructure (request
// deserializer, response serializer, SchemaProvider<BenchmarkContext>) via
// AddGraphQLSchema. Introspection is disabled per the benchmark contract.
// No fields are added in the callback because the schema below supersedes it.
builder.Services.AddGraphQLSchema<BenchmarkContext>(
    (Action<SchemaProvider<BenchmarkContext>>)(_ => { }),
    introspectionEnabled: false);

// Replace the SchemaProvider<BenchmarkContext> registration with one that
// resolves DatabaseService / CacheService from DI and builds the benchmark
// schema. A later registration for the same service type wins, so this keeps
// AddGraphQLSchema's infrastructure while supplying our schema implementation.
builder.Services.AddSingleton<SchemaProvider<BenchmarkContext>>(sp =>
    BenchmarkSchema.Configure(
        sp.GetRequiredService<DatabaseService>(),
        sp.GetRequiredService<CacheService>(),
        introspectionEnabled: false));

var app = builder.Build();

// MapGraphQL<TQueryType> expects the query context type (BenchmarkContext), not
// a schema class -- it looks up SchemaProvider<BenchmarkContext> from DI.
app.MapGraphQL<BenchmarkContext>("/graphql");

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();
