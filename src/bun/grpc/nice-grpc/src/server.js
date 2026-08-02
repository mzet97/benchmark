const { createServer } = require("nice-grpc");
const path = require("path");
const protoLoader = require("@grpc/proto-loader");
const grpc = require("@grpc/grpc-js");
const service = require("./service");
const db = require("./db");
const cache = require("./cache");

const PROTO_PATH = path.join(__dirname, "..", "proto", "benchmark.proto");
const PORT = parseInt(process.env.PORT || '8080');

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
  includeDirs: [path.join(__dirname, "..", "proto")],
});

const proto = grpc.loadPackageDefinition(packageDefinition).benchmark;

async function main() {
  const server = createServer();

  server.add(proto.BenchmarkService, service);

  const address = `0.0.0.0:${PORT}`;
  await server.listen(address);

  console.log(`nice-grpc server (Bun) listening on port ${PORT}`);
  console.log(`Version: ${process.env.APP_VERSION || "1.0.0"}`);

  // Graceful shutdown
  const shutdown = async () => {
    console.log("Shutting down nice-grpc server...");
    try {
      await server.shutdown();
      console.log("Server stopped accepting new connections");
      await db.close();
      await cache.close();
      console.log("Database and cache connections closed");
      process.exit(0);
    } catch (err) {
      console.error("Error during shutdown:", err);
      process.exit(1);
    }
  };

  const forceShutdown = setTimeout(() => {
    console.error("Forced shutdown after timeout");
    process.exit(1);
  }, 10000);
  forceShutdown.unref();

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main().catch((err) => {
  console.error("Failed to start server:", err);
  process.exit(1);
});
