using ProtoBuf.Grpc.Server;
using ProtobufNetGrpc.Contracts;
using ProtobufNetGrpc.Services;

var builder = WebApplication.CreateBuilder(args);

// Add protobuf-net.Grpc services
builder.Services.AddCodeFirstGrpc();
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

// Map gRPC service via code-first
app.MapGrpcService<BenchmarkServiceImpl>();

// Health check endpoint for Kubernetes
app.MapGet("/", () => "gRPC server (protobuf-net.Grpc) is running. Use a gRPC client to connect.");

app.Run();
