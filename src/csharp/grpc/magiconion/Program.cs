using MagicOnion;
using MagicOnionBenchmark.Services;

var builder = WebApplication.CreateBuilder(args);

// Add MagicOnion services
builder.Services.AddMagicOnion();
builder.Services.AddSingleton<DatabaseService>();
builder.Services.AddSingleton<CacheService>();

// Configure Kestrel for gRPC
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(50051, listenOptions =>
    {
        listenOptions.Protocols = Microsoft.AspNetCore.Server.Kestrel.Core.HttpProtocols.Http2;
    });
});

var app = builder.Build();

// Map MagicOnion gRPC service
app.MapMagicOnionService();

// Health check endpoint for Kubernetes
app.MapGet("/", () => "gRPC server (MagicOnion) is running. Use a gRPC client to connect.");

app.Run();
