import path from 'path';
import protoLoader from '@grpc/proto-loader';
import grpc from '@grpc/grpc-js';
import { fileURLToPath } from 'url';

// ESM has no __dirname; derive it from import.meta.url.
const __dirname = path.dirname(fileURLToPath(import.meta.url));

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

export { proto, PROTO_PATH };