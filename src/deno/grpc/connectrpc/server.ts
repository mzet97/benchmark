import { createGrpcTransport } from "@connectrpc/connect-node";
import { resolve } from "https://deno.land/std@0.224.0/path/mod.ts";
import * as service from "./service.ts";
import * as db from "./db.ts";
import * as cache from "./cache.ts";

// Load proto using @grpc/proto-loader
import * as grpc from "@grpc/grpc-js";
import * as protoLoader from "@grpc/proto-loader";

const PROTO_PATH = resolve(import.meta.dirname ?? ".", "proto", "benchmark.proto");
const PORT = parseInt(Deno.env.get("PORT") || "8080");

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
  includeDirs: [resolve(import.meta.dirname ?? ".", "proto")],
});

const proto = (grpc.loadPackageDefinition(packageDefinition) as Record<string, unknown>)
  .benchmark as unknown as {
    BenchmarkService: { service: grpc.ServiceDefinition },
  };

// ConnectRPC on Deno: use a raw gRPC-js server with connect-style service methods
// Since @connectrpc/connect-node requires Node.js http2, we use the grpc-js adapter pattern
function main() {
  const server = new grpc.Server();

  server.addService(proto.BenchmarkService.service, {
    Health: service.Health,
    GetJsonItems: service.GetJsonItems,
    GetUser: service.GetUser,
    GetComplexOrders: service.GetComplexOrders,
    GetCacheValue: service.GetCacheValue,
  } as grpc.UntypedServiceImplementation);

  server.bindAsync(
    `0.0.0.0:${PORT}`,
    grpc.ServerCredentials.createInsecure(),
    (err: Error | null, port: number) => {
      if (err) {
        console.error("Failed to bind server:", err);
        Deno.exit(1);
      }
      console.log(`ConnectRPC server (Deno) listening on port ${port}`);
    }
  );

  // Graceful shutdown
  const shutdown = () => {
    console.log("Shutting down ConnectRPC server...");
    server.tryShutdown(() => {
      console.log("Server shut down gracefully");
      Deno.exit(0);
    });
  };

  Deno.addSignalListener("SIGINT", shutdown);
  Deno.addSignalListener("SIGTERM", shutdown);
}

main();
