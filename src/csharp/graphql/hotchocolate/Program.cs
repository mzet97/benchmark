using HotChocolate;
using HotChocolate.AspNetCore;
using GraphqlHotChocolate.Services;
using GraphqlHotChocolate.Types;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<DatabaseService>();
builder.Services.AddSingleton<CacheService>();

builder.Services
    .AddGraphQLServer()
    .AddQueryType<Query>()
    .AddType<HealthType>()
    .AddType<JsonItemType>()
    .AddType<JsonItemsResultType>()
    .AddType<UserType>()
    .AddType<UserOrderStatsType>()
    .AddType<ComplexOrdersResultType>()
    .AddType<CacheEntryType>()
    .DisableIntrospection();

var app = builder.Build();

app.MapGraphQL("/graphql");

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();
