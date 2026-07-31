import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';
import cluster from 'node:cluster';
import os from 'node:os';

// Node runs JavaScript on a single thread, so a bare bootstrap in a pod with
// 7 CPUs would use one of them. Every other runtime in this benchmark uses all
// the cores it is given. BENCH_CPUS comes from the shared ConfigMap.
// See docs/ACTION_PLAN.md, Fase 3.1.
function workerCount(): number {
  const requested = Number.parseInt(process.env.BENCH_CPUS ?? '', 10);
  return Number.isInteger(requested) && requested > 0
    ? requested
    : os.availableParallelism();
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Bootstrap');

  // 8080 is the contract port (deploy/k3s/base/configmap.yaml). This
  // previously defaulted to 3000, which does not match the Service target.
  const port = process.env.PORT || 8080;
  const host = '0.0.0.0';

  // No global prefix. The benchmark contract addresses /health, /json,
  // /db/simple, /db/complex and /cache at the root -- see
  // contracts/rest/canonical-payloads.md. The previous setGlobalPrefix('api')
  // moved every route to /api/*, so the load generator was hitting 404s.
  app.enableCors({
    origin: true,
    credentials: true,
  });

  await app.listen(port, host);
  logger.log(`Server running on http://${host}:${port}`);
  logger.log('Benchmark API ready');
}

const workers = workerCount();

if (cluster.isPrimary && workers > 1) {
  // eslint-disable-next-line no-console
  console.log(`Primary ${process.pid} starting ${workers} workers`);

  for (let i = 0; i < workers; i++) {
    cluster.fork();
  }

  // A worker dying mid-run would silently reduce capacity and skew the
  // measurement, so replace it and make the event visible in the logs.
  cluster.on('exit', (worker, code, signal) => {
    // eslint-disable-next-line no-console
    console.error(
      `Worker ${worker.process.pid} exited (code=${code} signal=${signal}); forking a replacement`,
    );
    cluster.fork();
  });
} else {
  void bootstrap();
}
