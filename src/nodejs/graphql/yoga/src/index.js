// Entry point for Node.js GraphQL (Yoga).
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

if (cluster.isPrimary && workers > 1) {
  console.log(`Primary ${process.pid} starting ${workers} workers`);

  for (let i = 0; i < workers; i++) {
    cluster.fork();
  }

  // A worker dying mid-run would silently reduce capacity and skew the
  // measurement, so replace it and make the event visible in the logs.
  cluster.on('exit', (worker, code, signal) => {
    console.error(
      `Worker ${worker.process.pid} exited (code=${code} signal=${signal}); forking a replacement`,
    );
    cluster.fork();
  });
} else {
  await import('./server.js');
}
