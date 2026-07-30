const grpc = require("@grpc/grpc-js");
const protoLoader = require("@grpc/proto-loader");
const path = require("path");
const service = require("./service");
const db = require("./db");
const cache = require("./cache");

const PROTO_PATH = path.join(__dirname, "..", "proto", "benchmark.proto");
const PORT = parseInt(process.env.PORT || "50051");

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
  includeDirs: [path.join(__dirname, "..", "proto")],
});

const proto = grpc.loadPackageDefinition(packageDefinition).benchmark;

function wrapService(impl) {
  const wrapped = {};
  for (const [key, fn] of Object.entries(impl)) {
    if (typeof fn !== "function") continue;
    const pascalKey = key.charAt(0).toUpperCase() + key.slice(1);
    wrapped[pascalKey] = async (call, callback) => {
      try {
        const result = await fn(call.request, {});
        callback(null, result);
      } catch (err) {
        callback(err);
      }
    };
  }
  return wrapped;
}

function main() {
  const server = new grpc.Server();
  server.addService(proto.BenchmarkService.service, wrapService(service));

  server.bindAsync(
    `0.0.0.0:${PORT}`,
    grpc.ServerCredentials.createInsecure(),
    (err, port) => {
      if (err) {
        console.error("Failed to bind server:", err);
        process.exit(1);
      }
      console.log(`gRPC server (Node/nice-grpc) listening on port ${port}`);
      console.log(`Version: ${process.env.APP_VERSION || "1.0.0"}`);
    }
  );

  const shutdown = () => {
    console.log("Shutting down gRPC server...");
    server.tryShutdown(async () => {
      console.log("Server shut down gracefully");
      try {
        await db.close();
        await cache.close();
        console.log("Database and cache connections closed");
      } catch (e) {
        console.error("Error closing connections:", e);
      }
      process.exit(0);
    });
  };

  const forceShutdown = setTimeout(() => {
    console.error("Forced shutdown after timeout");
    process.exit(1);
  }, 10000);
  forceShutdown.unref();

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main();
