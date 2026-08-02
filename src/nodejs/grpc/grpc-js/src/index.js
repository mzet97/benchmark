// Entry point for Node.js gRPC (grpc-js).
//
// Node runs JavaScript on a single thread, so a bare `node src/server.js` in a
// pod with 7 CPUs would use one of them. Every compiled runtime in this
// benchmark uses all the cores it is given, so leaving Node single-threaded
// measures "is this runtime multi-threaded", not the framework.
//
// cluster forks BENCH_CPUS workers that share one listening socket and
// round-robins accepted connections across them. BENCH_CPUS comes from the
// same ConfigMap every implementation reads.
// See docs/ACTION_PLAN.md, Fase 3.1.

import cluster from 'node:cluster';
import os from 'node:os';

const requested = Number.parseInt(process.env.BENCH_CPUS ?? '', 10);
const workers = Number.isInteger(requested) && requested > 0
  ? requested
  : os.availableParallelism();

// DB_POOL_MAX and REDIS_POOL_MAX are budgets for the whole pod, not for one
// worker. Forking N workers that each open DB_POOL_MAX connections would give
// this implementation N times the pool of a single-process one -- exactly the
// kind of hidden variable the contract exists to remove.
// See docs/ACTION_PLAN.md, Fase 3.2.
const share = (name, fallback) => {
  const total = Number.parseInt(process.env[name] ?? '', 10);
  const budget = Number.isInteger(total) && total > 0 ? total : fallback;
  return String(Math.max(1, Math.floor(budget / workers)));
};

const poolEnv = {
  DB_POOL_MAX: share('DB_POOL_MAX', 32),
  REDIS_POOL_MAX: share('REDIS_POOL_MAX', 32),
};

if (cluster.isPrimary && workers > 1) {
  console.log(`Primary ${process.pid} starting ${workers} workers`);

  for (let i = 0; i < workers; i++) {
    cluster.fork(poolEnv);
  }

  // A worker dying mid-run would silently reduce capacity and skew the
  // measurement, so replace it and make the event visible in the logs.
  cluster.on('exit', (worker, code, signal) => {
    console.error(
      `Worker ${worker.process.pid} exited (code=${code} signal=${signal}); forking a replacement`,
    );
    cluster.fork(poolEnv);
  });
} else {
  await import('./server.js');
}
