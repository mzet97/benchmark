const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');
const service = require('./service');
const db = require('./db');
const cache = require('./cache');

const PROTO_PATH = path.join(__dirname, '..', 'proto', 'benchmark.proto');
const PORT = parseInt(process.env.PORT || '50051');

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
  includeDirs: [path.join(__dirname, '..', 'proto')],
});

const proto = grpc.loadPackageDefinition(packageDefinition).benchmark;

function getServer() {
  const server = new grpc.Server();
  server.addService(proto.BenchmarkService.service, {
    Health: service.health,
    GetJsonItems: service.getJsonItems,
    GetUser: service.getUser,
    GetComplexOrders: service.getComplexOrders,
    GetCacheValue: service.getCacheValue,
  });
  return server;
}

async function main() {
  const server = getServer();

  const address = `0.0.0.0:${PORT}`;
  server.bindAsync(address, grpc.ServerCredentials.createInsecure(), (err, port) => {
    if (err) {
      console.error('Failed to bind server:', err);
      process.exit(1);
    }
    console.log(`gRPC server listening on port ${port}`);
    console.log(`Proto path: ${PROTO_PATH}`);
    console.log(`Version: ${process.env.APP_VERSION || '1.0.0'}`);
  });

  // Graceful shutdown
  const shutdown = async () => {
    console.log('Shutting down gRPC server...');
    server.tryShutdown(async () => {
      console.log('Server stopped accepting new connections');
      await db.close();
      await cache.close();
      console.log('Database and cache connections closed');
      process.exit(0);
    });

    // Force shutdown after 10 seconds
    setTimeout(() => {
      console.error('Forced shutdown after timeout');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
