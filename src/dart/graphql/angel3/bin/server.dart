import 'dart:io';
import 'dart:isolate';

import 'package:angel3_framework/angel3_framework.dart';
import 'package:angel3_framework/http.dart';
import 'package:angel3_graphql/angel3_graphql.dart';
import 'package:angel3_cors/angel3_cors.dart';

import 'package:graphql_angel3_benchmark/runtime.dart';
import 'package:graphql_angel3_benchmark/schema.dart';
import 'package:graphql_angel3_benchmark/db.dart';
import 'package:graphql_angel3_benchmark/cache.dart';

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

  final app = Angel();

  // CORS middleware
  app.fallback(corsMiddleware());

  // GraphQL endpoint
  final schema = buildSchema(db, cache);
  app.all('/graphql', graphQLHttp(schema));

  // Health endpoint
  app.get('/health', (req, res) async {
    return {'status': 'ok'};
  });

  // AngelHttp.custom with a shared bind: the default server generator is
  // HttpServer.bind without `shared`, so only the first isolate could have
  // taken the port. `startServer` also belongs to the driver, not to Angel --
  // `app.startServer`, what this called before, does not exist.
  final http = AngelHttp.custom(
    app,
    (address, port) => HttpServer.bind(address, port, shared: true),
  );

  final server = await http.startServer(InternetAddress.anyIPv4, port);
  stdout.writeln('Angel3 GraphQL worker $worker listening on port ${server.port}');
}
