using EntityGraphQL.AspNetCore;
using GraphqlEntityGraphQL.Services;
using GraphqlEntityGraphQL.Schema;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<DatabaseService>();
builder.Services.AddSingleton<CacheService>();

var app = builder.Build();

var db = app.Services.GetRequiredService<DatabaseService>();
var cache = app.Services.GetRequiredService<CacheService>();
var schema = BenchmarkSchema.Create(db, cache);

app.MapGraphQL<BenchmarkSchema>("/graphql");

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();
