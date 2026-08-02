// Entry point for the Bun GraphQL benchmark (Yoga).
//
// Bun runs JavaScript on a single thread, so a bare `bun run src/server.js` in
// a pod with 7 CPUs would use one of them. Every compiled runtime in this
// benchmark uses all the cores it is given, so leaving Bun single-threaded
// measures "is this runtime multi-threaded", not the framework.
//
// Bun has no cluster module: the idiomatic approach is N processes sharing one
// listening socket via SO_REUSEPORT, with the kernel balancing accepted
// connections across them. BENCH_CPUS comes from the same ConfigMap every
// implementation reads.
// See docs/ACTION_PLAN.md, Fase 3.1.

const requested = Number.parseInt(process.env.BENCH_CPUS ?? '', 10);
const workers = Number.isInteger(requested) && requested > 0
  ? requested
  : navigator.hardwareConcurrency;

if (workers > 1 && !process.env.BENCH_WORKER) {
  console.log(`Primary ${process.pid} starting ${workers} workers`);

  const fork = (index) => {
    Bun.spawn(['bun', 'run', 'src/server.js'], {
      env: { ...process.env, BENCH_WORKER: String(index) },
      stdout: 'inherit',
      stderr: 'inherit',
      onExit(_subprocess, exitCode, signalCode) {
        // A worker dying mid-run would silently reduce capacity and skew the
        // measurement, so replace it and make the event visible in the logs.
        console.error(
          `Worker ${index} exited (code=${exitCode} signal=${signalCode}); forking a replacement`,
        );
        fork(index);
      },
    });
  };

  for (let i = 0; i < workers; i++) fork(i);
} else {
  await import('./server.js');
}
