import * as grpc from "@grpc/grpc-js";
import * as protoLoader from "@grpc/proto-loader";
import { resolve } from "https://deno.land/std@0.224.0/path/mod.ts";
import service from "./service.ts";
import * as db from "./db.ts";
import * as cache from "./cache.ts";

const PROTO_PATH = resolve(import.meta.dirname ?? ".", "proto", "benchmark.proto");
const PORT = parseInt(Deno.env.get("PORT") || "50051");

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
  includeDirs: [resolve(import.meta.dirname ?? ".", "proto")],
});

const proto = (grpc.loadPackageDefinition(packageDefinition) as Record<string, unknown>)
  .benchmark as Record<string, unknown>;
const BenchmarkService = (proto as Record<string, { service: unknown }>).BenchmarkService.service;

function wrapService(impl: Record<string, unknown>): Record<string, unknown> {
  const wrapped: Record<string, unknown> = {};
  for (const [key, fn] of Object.entries(impl)) {
    if (typeof fn !== "function") continue;
    const pascalKey = key.charAt(0).toUpperCase() + key.slice(1);
    wrapped[pascalKey] = async (call: { request: unknown }, callback: (err: unknown, result?: unknown) => void) => {
      try {
        const result = await (fn as (req: unknown, ctx: unknown) => Promise<unknown>)(call.request, {});
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

  server.addService(BenchmarkService as grpc.ServiceDefinition, wrapService(service as Record<string, unknown>) as Record<string, unknown> as grpc.UntypedServiceImplementation);

  server.bindAsync(
    `0.0.0.0:${PORT}`,
    grpc.ServerCredentials.createInsecure(),
    (err: Error | null, port: number) => {
      if (err) {
        console.error("Failed to bind server:", err);
        Deno.exit(1);
      }
      console.log(`gRPC server (Deno/nice-grpc) listening on port ${port}`);
      console.log(`Version: ${Deno.env.get("APP_VERSION") || "1.0.0"}`);
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
      Deno.exit(0);
    });
  };

  Deno.addSignalListener("SIGINT", shutdown);
  Deno.addSignalListener("SIGTERM", shutdown);
}

main();
