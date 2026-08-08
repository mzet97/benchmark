using BenchmarkControllers.Services;
using Npgsql;

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

// Parse REDIS_URL to StackExchange.Redis format. Use Uri so the
// percent-encoded password is decoded.
var redisUrl = Environment.GetEnvironmentVariable("REDIS_URL") ?? "";
if (redisUrl.StartsWith("redis://") || redisUrl.StartsWith("rediss://"))
{
    var uri = new Uri(redisUrl);
    var password = uri.UserInfo;
    if (uri.UserInfo.Contains(':'))
    {
        password = uri.UserInfo.Substring(uri.UserInfo.IndexOf(':') + 1);
    }
    var host = uri.Host;
    var port = uri.Port != 0 ? uri.Port : 6379;
    builder.Configuration["Redis:ConnectionString"] =
        $"{host}:{port},password={password},abortConnect=false";
}

// Add controllers
builder.Services.AddControllers();

// Add Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Benchmark API - Controllers", Version = "v1" });
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

app.MapControllers();

app.Run();

// Make the implicit Program class public for testing
public partial class Program { }
