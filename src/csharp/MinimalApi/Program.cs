using BenchmarkApi.Handlers;
using BenchmarkApi.Services;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Mvc;

// The TTL is part of the response contract and must match the expiry the
// cache service writes. See contracts/rest/canonical-payloads.md.
const int CacheTtlSeconds = 300;

var builder = WebApplication.CreateBuilder(args);

// Parse DATABASE_URL to Npgsql format
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL") ?? "";
if (databaseUrl.StartsWith("postgresql://"))
{
    var lastAt = databaseUrl.LastIndexOf('@');
    var schemeEnd = databaseUrl.IndexOf("://");
    var userPass = databaseUrl.Substring(schemeEnd + 3, lastAt - schemeEnd - 3);
    var hostPortDb = databaseUrl.Substring(lastAt + 1);
    var user = userPass.Split(':')[0];
    var password = userPass.Contains(':') ? userPass.Substring(userPass.IndexOf(':') + 1) : "";
    var host = hostPortDb.Split(':')[0];
    var portDb = hostPortDb.Substring(hostPortDb.IndexOf(':') + 1);
    var port = portDb.Split('/')[0];
    var database = portDb.Contains('/') ? portDb.Substring(portDb.IndexOf('/') + 1) : "";
    var npgsqlConn = $"Host={host};Port={port};Database={database};Username={user};Password={password};Maximum Pool Size=25;Connection Timeout=30";
    builder.Configuration["ConnectionStrings:DefaultConnection"] = npgsqlConn;
}

// Parse REDIS_URL to StackExchange.Redis format
var redisUrl = Environment.GetEnvironmentVariable("REDIS_URL") ?? "";
if (redisUrl.StartsWith("redis://"))
{
    var lastAt = redisUrl.LastIndexOf('@');
    var schemeEnd = redisUrl.IndexOf("://");
    var password = redisUrl.Substring(schemeEnd + 4, lastAt - schemeEnd - 4);
    var hostPort = redisUrl.Substring(lastAt + 1);
    var host = hostPort.Split(':')[0];
    var port = hostPort.Contains(':') ? hostPort.Split(':')[1] : "6379";
    builder.Configuration["Redis:ConnectionString"] = $"{host}:{port},password={password},abortConnect=false";
}

// Add services to the container
builder.Services.AddEndpointsApiExplorer();

// Add logging
builder.Services.AddLogging(config =>
{
    config.AddSimpleConsole(options =>
    {
        options.TimestampFormat = "yyyy-MM-dd HH:mm:ss ";
    });
});

// Add database services
builder.Services.AddSingleton<IDatabaseService, DatabaseService>();

// Add cache services
builder.Services.AddSingleton<ICacheService, CacheService>();

// Add health checks (simplified - custom /health endpoint handles DB/Redis checks)
builder.Services.AddHealthChecks();

var app = builder.Build();

// Health checks (Kubernetes compatible)
app.MapHealthChecks("/healthz", new HealthCheckOptions
{
    Predicate = _ => true,
});

// Configure routes with minimal overhead
app.MapGet("/", () => Results.Redirect("/health"));

// Endpoint 1: GET /health - Hello World (Simple)
app.MapGet("/health", () => Results.Ok(new { status = "ok", version = "1.0.0", timestamp = DateTime.UtcNow }));

// Endpoint 2: GET /json - Serialização JSON
app.MapGet("/json", JsonHandler.GetJson);

// Endpoint 3: GET /db/simple - Query simples
app.MapGet("/db/simple", async (
        [FromQuery] int? id,
        IDatabaseService databaseService,
        ILogger<Program> logger) =>
{
    if (!id.HasValue || id <= 0)
    {
        return Results.BadRequest(new { error = "Invalid id parameter" });
    }

    logger.LogInformation("Simple DB query requested for id: {Id}", id);
    var user = await databaseService.GetUserByIdAsync(id.Value);

    if (user == null)
    {
        return Results.NotFound(new { error = $"User with id {id} not found" });
    }
        // The contract returns the user object itself. The previous DTO was
        // {Id, Name, Email, CreatedAt, IsActive}: first and last name
        // concatenated, no age, and an IsActive flag computed from the row
        // age -- a shape no other implementation used.
        return Results.Ok(user);
})
.WithName("GetSimpleDb")
.WithDescription("Get user by ID from database");

// Endpoint 4: GET /db/complex - Query complexa
app.MapGet("/db/complex", async (
        [FromQuery] int? days,
        IDatabaseService databaseService,
        ILogger<Program> logger) =>
{
    var queryDays = days ?? 30;

    if (queryDays <= 0 || queryDays > 365)
    {
        return Results.BadRequest(new { error = "Days must be between 1 and 365" });
    }

    logger.LogInformation("Complex DB query requested for last {Days} days", queryDays);
    var results = await databaseService.GetComplexQueryAsync(queryDays);

    return Results.Ok(new
    {
        periodDays = queryDays,
        totalUsers = results.Length,
        data = results
    });
})
.WithName("GetComplexDb")
.WithDescription("Complex query with JOIN and aggregation");

// Endpoint 5: GET /cache - Leitura Redis
app.MapGet("/cache", async (
        [FromQuery] string? key,
        ICacheService cacheService,
        ILogger<Program> logger) =>
{
    if (string.IsNullOrEmpty(key))
    {
        return Results.BadRequest(new { error = "Key parameter is required" });
    }

    logger.LogInformation("Cache request for key: {Key}", key);

    var (value, cached) = await cacheService.GetOrSetAsync(key, async () =>
    {
        return $"Cached value for {key} at {DateTime.UtcNow:O}";
    });

    return Results.Ok(new
    {
        key,
        value,
        cached,
            ttl = CacheTtlSeconds,
        timestamp = DateTime.UtcNow
    });
})
.WithName("GetCache")
.WithDescription("Get/set value in Redis cache");

// Add latency tracking middleware
app.Use(async (context, next) =>
{
    var start = DateTime.UtcNow;
    await next();
    var duration = DateTime.UtcNow - start;

    if (context.Request.Path.StartsWithSegments("/api") ||
        context.Request.Path.StartsWithSegments("/db") ||
        context.Request.Path == "/health" ||
        context.Request.Path == "/json" ||
        context.Request.Path == "/cache")
    {
        app.Logger.LogInformation(
            "{Method} {Path} - {StatusCode} - {Duration}ms",
            context.Request.Method,
            context.Request.Path,
            context.Response.StatusCode,
            duration.TotalMilliseconds);
    }
});

app.Run();

// Make the implicit Program class public for testing
public partial class Program { }
