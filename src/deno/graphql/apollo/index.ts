// Entry point for the Deno Apollo GraphQL benchmark.
//
// Deno runs JavaScript on a single thread, so a bare `deno run server.ts` in a
// pod with 7 CPUs would use one of them. Every compiled runtime in this
// benchmark uses all the cores it is given, so leaving Deno single-threaded
// measures "is this runtime multi-threaded", not the framework.
//
// Deno has no cluster module, and a Web Worker cannot own a listening socket.
// The idiomatic approach is N processes sharing one socket through
// SO_REUSEPORT -- `reusePort` on Deno.serve -- with the kernel balancing
// accepted connections across them. BENCH_CPUS comes from the same ConfigMap
// every implementation reads.
// See docs/ACTION_PLAN.md, Fase 3.1.

const requested = Number.parseInt(Deno.env.get("BENCH_CPUS") ?? "", 10);
const workers = Number.isInteger(requested) && requested > 0
  ? requested
  : navigator.hardwareConcurrency;

// DB_POOL_MAX and REDIS_POOL_MAX are budgets for the whole pod, not for one
// worker. Spawning N workers that each open DB_POOL_MAX connections would give
// this implementation N times the pool of a single-process one -- exactly the
// kind of hidden variable the contract exists to remove.
// See docs/ACTION_PLAN.md, Fase 3.2.
const share = (name: string, fallback: number): string => {
  const total = Number.parseInt(Deno.env.get(name) ?? "", 10);
  const budget = Number.isInteger(total) && total > 0 ? total : fallback;
  return String(Math.max(1, Math.floor(budget / workers)));
};

const poolEnv = {
  DB_POOL_MAX: share("DB_POOL_MAX", 32),
  REDIS_POOL_MAX: share("REDIS_POOL_MAX", 32),
};

if (workers > 1 && !Deno.env.get("BENCH_WORKER")) {
  console.log(`Primary ${Deno.pid} starting ${workers} workers`);

  const spawn = (index: number) => {
    const child = new Deno.Command(Deno.execPath(), {
      args: ["run", "--allow-net", "--allow-env", "--allow-read", "server.ts"],
      // Deno.Command inherits the parent environment unless clearEnv is set,
      // so the worker still sees PORT, BENCH_CPUS and the rest of the ConfigMap.
      env: { ...poolEnv, BENCH_WORKER: String(index) },
      stdout: "inherit",
      stderr: "inherit",
    }).spawn();

    // A worker dying mid-run would silently reduce capacity and skew the
    // measurement, so replace it and make the event visible in the logs.
    child.status.then(({ code, signal }) => {
      console.error(
        `Worker ${index} exited (code=${code} signal=${signal}); spawning a replacement`,
      );
      spawn(index);
    });
  };

  for (let i = 0; i < workers; i++) spawn(i);
} else {
  await import("./server.ts");
}
