using BenchmarkApi.Handlers;
using BenchmarkApi.Services;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Mvc;

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
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Benchmark API", Version = "v1" });
});

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

// Add health checks
builder.Services.AddHealthChecks()
    .AddNpgSql(builder.Configuration.GetConnectionString("DefaultConnection")!)
    .AddRedis(builder.Configuration["Redis:ConnectionString"]!);

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Health checks (Kubernetes compatible)
app.MapHealthChecks("/healthz", new HealthCheckOptions
{
    Predicate = _ => true,
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

// Configure routes with minimal overhead
app.MapGet("/", () => Results.Redirect("/health"));

// Endpoint 1: GET /health - Hello World (Simple)
app.MapGet("/health", () => Results.Ok(new { status = "ok", timestamp = DateTime.UtcNow }));

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

    var userDto = new
    {
        Id = user.Id,
        Name = $"{user.FirstName} {user.LastName}",
        Email = user.Email,
        CreatedAt = user.CreatedAt,
        IsActive = user.CreatedAt > DateTime.UtcNow.AddYears(-1)
    };

    return Results.Ok(userDto);
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
        period_days = queryDays,
        total_users = results.Length,
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

    var value = await cacheService.GetOrSetAsync(key, async () =>
    {
        await Task.Delay(50); // Simulate some work
        return $"Cached value for {key} at {DateTime.UtcNow:O}";
    });

    return Results.Ok(new
    {
        key,
        value,
        cached = value.Contains("Cached value"),
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
