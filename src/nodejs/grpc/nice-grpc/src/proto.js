const path = require('path');
const protoLoader = require('@grpc/proto-loader');
const grpc = require('@grpc/grpc-js');

const PROTO_PATH = path.join(__dirname, '..', 'proto', 'benchmark.proto');

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
  includeDirs: [path.join(__dirname, '..', 'proto')],
});

const proto = grpc.loadPackageDefinition(packageDefinition).benchmark;

module.exports = { proto, PROTO_PATH };
