const grpc = require("@grpc/grpc-js");
const protoLoader = require("@grpc/proto-loader");
const path = require("path");
const service = require("./service");

const PROTO_PATH = path.join(__dirname, "..", "proto", "benchmark.proto");
const PORT = parseInt(process.env.PORT || '8080');

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
});

const proto = grpc.loadPackageDefinition(packageDefinition).benchmark;

function main() {
  const server = new grpc.Server();

  server.addService(proto.BenchmarkService.service, {
    Health: service.Health,
    GetJsonItems: service.GetJsonItems,
    GetUser: service.GetUser,
    GetComplexOrders: service.GetComplexOrders,
    GetCacheValue: service.GetCacheValue,
  });

  server.bindAsync(
    `0.0.0.0:${PORT}`,
    grpc.ServerCredentials.createInsecure(),
    (err, port) => {
      if (err) {
        console.error("Failed to bind server:", err);
        process.exit(1);
      }
      console.log(`gRPC server running on port ${port}`);
    }
  );

  // Graceful shutdown
  const shutdown = () => {
    console.log("Shutting down gRPC server...");
    server.tryShutdown(() => {
      console.log("Server shut down gracefully");
      process.exit(0);
    });
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main();
