import * as grpc from "@grpc/grpc-js";
import * as protoLoader from "@grpc/proto-loader";
import { resolve } from "https://deno.land/std@0.224.0/path/mod.ts";
import * as service from "./service.ts";

const PROTO_PATH = resolve(import.meta.dirname ?? ".", "proto", "benchmark.proto");
const PORT = parseInt(Deno.env.get("PORT") || "50051");

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
});

const proto = (grpc.loadPackageDefinition(packageDefinition) as Record<string, unknown>)
  .benchmark as Record<string, unknown>;
const BenchmarkService = (proto as Record<string, { service: unknown }>).BenchmarkService.service;

function main() {
  const server = new grpc.Server();

  server.addService(BenchmarkService as grpc.ServiceDefinition, {
    Health: service.Health,
    GetJsonItems: service.GetJsonItems,
    GetUser: service.GetUser,
    GetComplexOrders: service.GetComplexOrders,
    GetCacheValue: service.GetCacheValue,
  });

  server.bindAsync(
    `0.0.0.0:${PORT}`,
    grpc.ServerCredentials.createInsecure(),
    (err: Error | null, port: number) => {
      if (err) {
        console.error("Failed to bind server:", err);
        Deno.exit(1);
      }
      console.log(`gRPC server running on port ${port}`);
    }
  );

  // Graceful shutdown
  const shutdown = () => {
    console.log("Shutting down gRPC server...");
    server.tryShutdown(() => {
      console.log("Server shut down gracefully");
      Deno.exit(0);
    });
  };

  Deno.addSignalListener("SIGINT", shutdown);
  Deno.addSignalListener("SIGTERM", shutdown);
}

main();
