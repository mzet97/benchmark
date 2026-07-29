const fastify = require("fastify")({ http2: true });
const { fastifyConnectPlugin } = require("@connectrpc/connect-fastify");
const { createGrpcTransport } = require("@connectrpc/connect-node");
const service = require("./service");
const db = require("./db");
const cache = require("./cache");

const PORT = parseInt(process.env.PORT || "50051");

// Define the service using proto descriptor
// ConnectRPC works with service definitions; we define the service inline
// matching the proto contract
const benchmarkService = {
  name: "BenchmarkService",
  fullName: "benchmark.BenchmarkService",
  methods: {
    health: {
      name: "Health",
      localName: "health",
      I: { typeName: "benchmark.HealthRequest", fields: [], encode: (v) => v, decode: (v) => v },
      O: { typeName: "benchmark.HealthResponse", fields: [], encode: (v) => v, decode: (v) => v },
      kind: "unary",
    },
    getJsonItems: {
      name: "GetJsonItems",
      localName: "getJsonItems",
      I: { typeName: "benchmark.JsonItemsRequest", fields: [], encode: (v) => v, decode: (v) => v },
      O: { typeName: "benchmark.JsonItemsResponse", fields: [], encode: (v) => v, decode: (v) => v },
      kind: "unary",
    },
    getUser: {
      name: "GetUser",
      localName: "getUser",
      I: { typeName: "benchmark.GetUserRequest", fields: [], encode: (v) => v, decode: (v) => v },
      O: { typeName: "benchmark.UserResponse", fields: [], encode: (v) => v, decode: (v) => v },
      kind: "unary",
    },
    getComplexOrders: {
      name: "GetComplexOrders",
      localName: "getComplexOrders",
      I: { typeName: "benchmark.ComplexOrdersRequest", fields: [], encode: (v) => v, decode: (v) => v },
      O: { typeName: "benchmark.ComplexOrdersResponse", fields: [], encode: (v) => v, decode: (v) => v },
      kind: "unary",
    },
    getCacheValue: {
      name: "GetCacheValue",
      localName: "getCacheValue",
      I: { typeName: "benchmark.CacheRequest", fields: [], encode: (v) => v, decode: (v) => v },
      O: { typeName: "benchmark.CacheResponse", fields: [], encode: (v) => v, decode: (v) => v },
      kind: "unary",
    },
  },
};

async function main() {
  await fastify.register(fastifyConnectPlugin, {
    routes: (router) => {
      router.service(benchmarkService, service);
    },
  });

  await fastify.listen({ host: "0.0.0.0", port: PORT });

  console.log(`ConnectRPC server (Bun) listening on port ${PORT}`);
  console.log(`Version: ${process.env.APP_VERSION || "1.0.0"}`);

  // Graceful shutdown
  const shutdown = async () => {
    console.log("Shutting down ConnectRPC server...");
    try {
      await fastify.close();
      await db.close();
      await cache.close();
      console.log("Server shut down gracefully");
      process.exit(0);
    } catch (err) {
      console.error("Error during shutdown:", err);
      process.exit(1);
    }
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main().catch((err) => {
  console.error("Failed to start server:", err);
  process.exit(1);
});
