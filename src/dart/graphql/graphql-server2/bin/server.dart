import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:graphql_server2_benchmark/runtime.dart';
import 'package:graphql_server2_benchmark/schema.dart';
import 'package:graphql_server2_benchmark/resolvers.dart';

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
  // 8080 is the contract port: the Service targets one port and the runner
  // builds one URL. The fallback here was 3000.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final resolvers = Resolvers();
  await resolvers.initialize();

  // Built once. This used to run inside the request handler, so every request
  // paid for building and validating the whole schema -- work no other GraphQL
  // implementation in this benchmark does per request.
  final schema = buildSchema(resolvers);

  final router = Router();

  router.post('/graphql', (shelf.Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> payload = json.decode(body);

    final query = payload['query'] as String? ?? '';
    final variables = payload['variables'] as Map<String, dynamic>?;
    final operationName = payload['operationName'] as String?;

    final result = await schema.parseAndExecute(
      query,
      variableValues: variables ?? const {},
      operationName: operationName,
    );

    return shelf.Response.ok(
      json.encode(result),
      headers: {'content-type': 'application/json'},
    );
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
  stdout.writeln('Dart GraphQL worker $worker listening on port ${server.port}');
}
