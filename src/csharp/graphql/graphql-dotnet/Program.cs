using GraphQL;
using GraphQL.Types;
using GraphqlDotnet.Services;
using GraphqlDotnet.Schema;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<DatabaseService>();
builder.Services.AddSingleton<CacheService>();
builder.Services.AddSingleton<BenchmarkSchema>();

var app = builder.Build();

var schema = app.Services.GetRequiredService<BenchmarkSchema>();

app.Map("/graphql", async (HttpContext context) =>
{
    if (context.Request.Method != "POST")
    {
        context.Response.StatusCode = 405;
        await context.Response.WriteAsync("Method not allowed");
        return;
    }

    var request = await context.Request.ReadFromJsonAsync<GraphQLRequest>();
    if (request == null)
    {
        context.Response.StatusCode = 400;
        await context.Response.WriteAsync("Bad request");
        return;
    }

    var result = await new DocumentExecuter().ExecuteAsync(executionOptions =>
    {
        executionOptions.Schema = schema;
        executionOptions.Query = request.Query;
        executionOptions.Variables = request.Variables;
        executionOptions.OperationName = request.OperationName;
    });

    context.Response.ContentType = "application/json";
    await context.Response.WriteAsJsonAsync(new
    {
        data = result.Data,
        errors = result.Errors?.Select(e => new { message = e.Message })
    });
});

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();

public class GraphQLRequest
{
    public string Query { get; set; } = "";
    public object? Variables { get; set; }
    public string? OperationName { get; set; }
}
