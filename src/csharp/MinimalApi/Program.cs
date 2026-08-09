using BenchmarkApi.Handlers;
using BenchmarkApi.Services;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

// The TTL is part of the response contract and must match the expiry the
// cache service writes. See contracts/rest/canonical-payloads.md.
const int CacheTtlSeconds = 300;

var builder = WebApplication.CreateBuilder(args);

// Build the Npgsql connection string from the component ConfigMap/Secret
// variables (DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD). The previous code
// hand-parsed DATABASE_URL and did not percent-decode the userinfo, so the
// literal "Admin%40123" was sent to Postgres and authentication failed for
// db_admin -- every /db/* and the health probe came back empty. Using the
// component variables sidesteps URL parsing and the encoded password entirely.
var dbHost = Environment.GetEnvironmentVariable("DB_HOST");
var dbPort = Environment.GetEnvironmentVariable("DB_PORT") ?? "5432";
var dbName = Environment.GetEnvironmentVariable("DB_NAME");
var dbUser = Environment.GetEnvironmentVariable("DB_USER");
var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");
var dbPoolMax = Environment.GetEnvironmentVariable("DB_POOL_MAX") ?? "32";

if (!string.IsNullOrEmpty(dbHost) && !string.IsNullOrEmpty(dbName))
{
    var npgsqlConn = new NpgsqlConnectionStringBuilder
    {
        Host = dbHost,
        Port = int.Parse(dbPort),
        Database = dbName,
        Username = dbUser,
        Password = dbPassword,
        Pooling = true,
        MaxPoolSize = int.Parse(dbPoolMax),
        Timeout = 30,
    }.ToString();
    builder.Configuration["ConnectionStrings:DefaultConnection"] = npgsqlConn;
}
else
{
    // Fall back to DATABASE_URL for local dev, parsing it through Npgsql's own
    // builder which percent-decodes the userinfo correctly.
    var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL") ?? "";
    if (!string.IsNullOrEmpty(databaseUrl))
    {
        try
        {
            var npgsqlConn = new NpgsqlConnectionStringBuilder(databaseUrl)
            {
                Pooling = true,
                MaxPoolSize = int.Parse(dbPoolMax),
                Timeout = 30,
            }.ToString();
            builder.Configuration["ConnectionStrings:DefaultConnection"] = npgsqlConn;
        }
        catch
        {
            builder.Configuration["ConnectionStrings:DefaultConnection"] = databaseUrl;
        }
    }
}

// Build the Redis connection from the component ConfigMap variables
// (REDIS_HOST/REDIS_PORT/REDIS_PASSWORD). REDIS_URL is percent-encoded
// (redis://:Admin%40123@host:6379) and the previous hand-rolled parser did
// not decode "%40" -> "@", so the literal "Admin%40123" was sent to Redis and
// auth failed -- cache:down. Reading the already-decoded REDIS_PASSWORD
// sidesteps URL parsing. The StackExchange config string is still published
// under Redis:ConnectionString so the CacheService can consume it.
var redisHost = Environment.GetEnvironmentVariable("REDIS_HOST");
var redisPort = Environment.GetEnvironmentVariable("REDIS_PORT") ?? "6379";
var redisPassword = Environment.GetEnvironmentVariable("REDIS_PASSWORD");

if (!string.IsNullOrEmpty(redisHost))
{
    builder.Configuration["Redis:ConnectionString"] = string.IsNullOrEmpty(redisPassword)
        ? $"{redisHost}:{redisPort},abortConnect=false"
        : $"{redisHost}:{redisPort},password={redisPassword},abortConnect=false";
}
else
{
    // Fall back to REDIS_URL for local dev, decoding via Uri.
    var redisUrl = Environment.GetEnvironmentVariable("REDIS_URL") ?? "";
    if (!string.IsNullOrEmpty(redisUrl))
    {
        try
        {
            var uri = new Uri(redisUrl);
            var host = uri.Host;
            var port = uri.Port > 0 ? uri.Port.ToString() : "6379";
            var pass = uri.UserInfo.Length > 1 ? Uri.UnescapeDataString(uri.UserInfo.Substring(1)) : "";
            builder.Configuration["Redis:ConnectionString"] = string.IsNullOrEmpty(pass)
                ? $"{host}:{port},abortConnect=false"
                : $"{host}:{port},password={pass},abortConnect=false";
        }
        catch
        {
            builder.Configuration["Redis:ConnectionString"] = redisUrl;
        }
    }
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

// Kestrel defaults to http://localhost:5000, which is unreachable from outside
// the pod: the Kubernetes readiness/liveness probes connect to TCP :8080 over
// the pod network and saw "connection refused", so the app ran (logs showed
// "Application started") but the pod never went Ready. Bind explicitly to
// 0.0.0.0 on the PORT the ConfigMap provides (default 8080).
var listenPort = Environment.GetEnvironmentVariable("PORT");
if (string.IsNullOrWhiteSpace(listenPort))
{
    listenPort = builder.Configuration["PORT"];
}
if (string.IsNullOrWhiteSpace(listenPort))
{
    listenPort = "8080";
}
app.Urls.Add($"http://0.0.0.0:{listenPort}");

// Health checks (Kubernetes compatible)
app.MapHealthChecks("/healthz", new HealthCheckOptions
{
    Predicate = _ => true,
});

// Configure routes with minimal overhead
app.MapGet("/", () => Results.Redirect("/health"));

// Endpoint 1: GET /health - Hello World (Simple)
// Contract: {"status","version","timestamp","database","cache"}. The previous
// response omitted database/cache, so it never matched (3 keys instead of 5).
app.MapGet("/health", async (
        IDatabaseService databaseService,
        ICacheService cacheService) =>
{
    var dbOk = await CheckDatabaseAsync(databaseService);
    var cacheOk = await CheckCacheAsync(cacheService);

    return Results.Ok(new
    {
        status = dbOk && cacheOk ? "ok" : "degraded",
        version = "1.0.0",
        timestamp = DateTime.UtcNow,
        database = dbOk ? "up" : "down",
        cache = cacheOk ? "up" : "down"
    });
});

// GetUserByIdAsync opens a real connection; the probe id does not need to
// exist -- the connection succeeding is what we measure.
static async Task<bool> CheckDatabaseAsync(IDatabaseService databaseService)
{
    try
    {
        await databaseService.GetUserByIdAsync(1);
        return true;
    }
    catch
    {
        return false;
    }
}

// A round-trip that exercises the Redis connection.
static async Task<bool> CheckCacheAsync(ICacheService cacheService)
{
    try
    {
        await cacheService.GetOrSetAsync("__healthcheck__", async () => "ok");
        return true;
    }
    catch
    {
        return false;
    }
}

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
