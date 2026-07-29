using BenchmarkFastEndpoints.Services;
using FastEndpoints;

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

// Add FastEndpoints
builder.Services.AddFastEndpoints();

// Add Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Benchmark API - FastEndpoints", Version = "v1" });
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
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Add latency tracking middleware
app.Use(async (context, next) =>
{
    var start = DateTime.UtcNow;
    await next();
    var duration = DateTime.UtcNow - start;

    app.Logger.LogInformation(
        "{Method} {Path} - {StatusCode} - {Duration}ms",
        context.Request.Method,
        context.Request.Path,
        context.Response.StatusCode,
        duration.TotalMilliseconds);
});

app.UseFastEndpoints();

app.Run();

// Make the implicit Program class public for testing
public partial class Program { }
