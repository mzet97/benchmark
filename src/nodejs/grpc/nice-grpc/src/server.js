const { createServer } = require('nice-grpc');
const { proto } = require('./proto');
const service = require('./service');
const db = require('./db');
const cache = require('./cache');

const PORT = parseInt(process.env.PORT || '8080');

async function main() {
  const server = createServer();

  server.add(proto.BenchmarkService, service);

  const address = `0.0.0.0:${PORT}`;
  await server.listen(address);

  console.log(`nice-grpc server listening on port ${PORT}`);
  console.log(`Version: ${process.env.APP_VERSION || '1.0.0'}`);

  // Graceful shutdown
  const shutdown = async () => {
    console.log('Shutting down nice-grpc server...');
    try {
      await server.shutdown();
      console.log('Server stopped accepting new connections');
      await db.close();
      await cache.close();
      console.log('Database and cache connections closed');
      process.exit(0);
    } catch (err) {
      console.error('Error during shutdown:', err);
      process.exit(1);
    }
  };

  // Force shutdown after 10 seconds
  const forceShutdown = setTimeout(() => {
    console.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
  forceShutdown.unref();

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
