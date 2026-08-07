import 'dart:io';
import 'dart:isolate';

import 'package:grpc/grpc.dart';

import '../lib/src/cache.dart';
import '../lib/src/db.dart';
import '../lib/src/runtime.dart';
import '../lib/src/service.dart';

Future<void> main() async {
  // BENCH_CPUS isolates, each running the whole gRPC server, all accepting
  // from one socket opened with shared: true. Dart runs a single isolate by
  // default, which in a 7-CPU pod would use one core.
  // See docs/ACTION_PLAN.md, Fase 3.1.
  final workers = benchWorkers();
  for (var i = 1; i < workers; i++) {
    await Isolate.spawn(_serve, i);
  }
  await _serve(0);
}

Future<void> _serve(int worker) async {
  // PORT, not GRPC_PORT: GRPC_PORT is not in the ConfigMap, so this server
  // would have listened on 50051 while the Service targeted 8080 -- the pod
  // would never have become reachable. Same defect the Python gRPC servers
  // had. See docs/ACTION_PLAN.md, Fase 3.4.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final db = Database();
  final cache = Cache();

  // Pre-warm connections
  final dbStatus = await db.checkDatabase();
  final cacheStatus = await cache.checkCache();
  stdout.writeln('Worker $worker database=$dbStatus cache=$cacheStatus');

  final service = BenchmarkServiceImpl(db, cache);

  final server = Server.create(
    services: [service],
    codecRegistry: CodecRegistry(
      codecs: const [GzipCodec(), IdentityCodec()],
    ),
  );

  // shared: true opens the listening socket with SO_REUSEPORT so every isolate
  // accepts from it, instead of every isolate but the first failing to bind.
  await server.serve(port: port, shared: true);
  stdout.writeln('gRPC worker $worker listening on port $port');

  // Only the first isolate handles signals; N isolates racing to close the
  // same pod's connections buys nothing.
  if (worker != 0) return;

  Future<void> shutdown() async {
    stdout.writeln('Shutting down gracefully...');
    await server.shutdown();
    await db.close();
    await cache.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => shutdown());
  ProcessSignal.sigterm.watch().listen((_) => shutdown());
}
