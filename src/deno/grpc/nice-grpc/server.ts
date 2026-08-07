import { createServer } from "nice-grpc";
import { resolve } from "https://deno.land/std@0.224.0/path/mod.ts";
import * as service from "./service.ts";
import * as db from "./db.ts";
import * as cache from "./cache.ts";

// Load proto using @grpc/proto-loader (npm compat)
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
  .benchmark as Record<string, { BenchmarkService: unknown }>;

async function main() {
  const server = createServer();

  server.add(
    (proto as Record<string, { BenchmarkService: unknown }>).BenchmarkService as never,
    service as never,
  );

  const address = `0.0.0.0:${PORT}`;
  await server.listen(address);

  console.log(`nice-grpc server (Deno) listening on port ${PORT}`);
  console.log(`Version: ${Deno.env.get("APP_VERSION") || "1.0.0"}`);

  // Graceful shutdown
  const shutdown = async () => {
    console.log("Shutting down nice-grpc server...");
    try {
      await server.shutdown();
      console.log("Server stopped accepting new connections");
      await db.close();
      await cache.close();
      console.log("Database and cache connections closed");
      Deno.exit(0);
    } catch (err) {
      console.error("Error during shutdown:", err);
      Deno.exit(1);
    }
  };

  Deno.addSignalListener("SIGINT", shutdown);
  Deno.addSignalListener("SIGTERM", shutdown);
}

main().catch((err) => {
  console.error("Failed to start server:", err);
  Deno.exit(1);
});
