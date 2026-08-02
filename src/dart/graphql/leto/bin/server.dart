import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:leto/leto.dart';
import 'package:leto_shelf/leto_shelf.dart';

import 'package:graphql_leto_benchmark/runtime.dart';
import 'package:graphql_leto_benchmark/schema.dart';
import 'package:graphql_leto_benchmark/db.dart';
import 'package:graphql_leto_benchmark/cache.dart';

Future<void> main(List<String> args) async {
  // BENCH_CPUS isolates, each running the whole server, all accepting from one
  // socket opened with shared: true. Dart runs a single isolate by default,
  // which in a 7-CPU pod would use one core.
  // See docs/ACTION_PLAN.md, Fase 3.1.
  final workers = benchWorkers();
  for (var i = 1; i < workers; i++) {
    await Isolate.spawn(_serve, i);
  }
  await _serve(0);
}

Future<void> _serve(int worker) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final db = DatabaseService();
  final cache = CacheService();
  await db.initialize();
  await cache.initialize();

  final schema = buildSchema(db, cache);

  final graphqlHandler = GraphQLHandler(schema);

  final router = Router();

  router.post('/graphql', (shelf.Request request) async {
    return graphqlHandler.handle(request);
  });

  router.get('/health', (shelf.Request request) async {
    return shelf.Response.ok(
      json.encode({'status': 'ok'}),
      headers: {'content-type': 'application/json'},
    );
  });

  // shelf.logRequests() is gone from the measured path: it wrote a line per
  // request while the ConfigMap sets LOG_LEVEL=error, and per-request logging
  // is a 2-3x difference between implementations.
  final handler = const shelf.Pipeline().addHandler(router.call);

  // shared: true opens the socket with SO_REUSEPORT so every isolate accepts
  // from it; poweredByHeader would put an X-Powered-By line on every response,
  // which no other implementation here sends.
  final server = await io.serve(
    handler,
    InternetAddress.anyIPv4,
    port,
    shared: true,
    poweredByHeader: null,
  );
  server.autoCompress = false;
  stdout.writeln('Leto GraphQL worker $worker listening on port ${server.port}');
}
