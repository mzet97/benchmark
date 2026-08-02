import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart' show Pipeline;

import 'package:benchmark_dart_vaden/services/database_service.dart';
import 'package:benchmark_dart_vaden/services/cache_service.dart';
import 'package:benchmark_dart_vaden/runtime.dart';
import 'package:benchmark_dart_vaden/utils/logger.dart';
import 'package:benchmark_dart_vaden/canonical.dart';

// The TTL is part of the response contract and must match what is written
// to Redis. See contracts/rest/canonical-payloads.md.
const cacheTtlSeconds = 300;

late DatabaseService databaseService;
late CacheService cacheService;

Future<void> main(List<String> args) async {
  // Dart's equivalent of Node's cluster module: BENCH_CPUS isolates, each
  // running the whole server, all accepting from one socket opened with
  // shared: true. Isolates do not share memory, so every one of them builds
  // its own router, pool and Redis client -- which is the point.
  // See docs/ACTION_PLAN.md, Fase 3.1.
  final workers = benchWorkers();
  for (var i = 1; i < workers; i++) {
    await Isolate.spawn(_serve, i);
  }
  await _serve(0);
}

Future<void> _serve(int worker) async {
  setupLogger();

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? '0.0.0.0';

  // Initialize services
  logger.info('Initializing services...');
  databaseService = DatabaseService();
  cacheService = CacheService();

  try {
    await databaseService.init();
    await cacheService.init();
    logger.info('Services initialized successfully');
  } catch (e) {
    logger.warning('Service initialization failed: $e');
    logger.warning('Running in degraded mode (no DB/Redis)');
  }

  // Setup routes
  final router = Router();

  // Health endpoints
  router.get('/health', _healthHandler);
  router.get('/healthz', _healthzHandler);
  router.get('/readyz', _readyzHandler);

  // Benchmark endpoints
  router.get('/json', _jsonHandler);
  router.get('/db/simple', _simpleDbHandler);
  router.get('/db/complex', _complexDbHandler);
  router.get('/cache', _cacheHandler);

  // Root
  router.get('/', _rootHandler);

  // Middleware pipeline.
  //
  // The logging middleware is gone from the measured path: it wrote a line per
  // request through package:logging while the ConfigMap sets LOG_LEVEL=error,
  // and per-request logging is a 2-3x difference between implementations.
  final handler = const Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(_errorMiddleware())
      .addHandler(router.call);

  // Start server. shared: true opens the socket with SO_REUSEPORT so every
  // isolate accepts from it; poweredByHeader would put an X-Powered-By line on
  // every response, which no other implementation here sends.
  final server = await shelf_io.serve(
    handler,
    host,
    port,
    shared: true,
    poweredByHeader: null,
  );
  server.autoCompress = false; // No compression for fair benchmark
  logger.info('Dart Vaden worker $worker listening on ${server.address.host}:${server.port}');

  // Graceful shutdown. Only the first isolate watches: ProcessSignal.watch
  // delivers to whoever is listening, and N isolates racing to close the same
  // pod's connections buys nothing.
  if (worker != 0) return;

  ProcessSignal.sigint.watch().listen((_) async {
    logger.info('Received SIGINT, shutting down...');
    await _shutdown();
    exit(0);
  });

  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) async {
      logger.info('Received SIGTERM, shutting down...');
      await _shutdown();
      exit(0);
    });
  }
}

Future<void> _shutdown() async {
  logger.info('Shutting down server...');
  await databaseService.close();
  await cacheService.close();
  logger.info('Server shutdown complete');
}

// === Middleware ===

shelf.Middleware _corsMiddleware() {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      if (request.method == 'OPTIONS') {
        return shelf.Response(204, headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        });
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
      });
    };
  };
}

shelf.Middleware _errorMiddleware() {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      try {
        return await innerHandler(request);
      } catch (error, stackTrace) {
        logger.severe('Unhandled error: $error', error, stackTrace);
        return shelf.Response.internalServerError(
          body: jsonEncode({
            'error': 'Internal Server Error',
            'message': Platform.environment['DEBUG'] == 'true' ? error.toString() : 'An error occurred',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

// === Handlers ===

shelf.Response _rootHandler(shelf.Request request) {
  return shelf.Response.ok(
    jsonEncode({
      'name': 'Benchmark API - Dart Vaden',
      'version': '1.0.0',
      'runtime': 'Dart ${Platform.version}',
      'framework': 'Vaden (Shelf)',
      'status': 'running',
    }),
    headers: {'content-type': 'application/json'},
  );
}

Future<shelf.Response> _healthHandler(shelf.Request request) async {
  final dbHealthy = await databaseService.healthCheck();
  final cacheHealthy = await cacheService.ping();

  final status = dbHealthy && cacheHealthy ? 'healthy' : 'degraded';
  final statusCode = dbHealthy && cacheHealthy ? 200 : 503;

  return shelf.Response(statusCode,
    body: jsonEncode({
      'status': status,
      'version': '1.0.0',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'database': dbHealthy ? 'connected' : 'disconnected',
      'cache': cacheHealthy ? 'connected' : 'disconnected',
    }),
    headers: {'content-type': 'application/json'},
  );
}

shelf.Response _healthzHandler(shelf.Request request) {
  return shelf.Response.ok(
    jsonEncode({'status': 'ok'}),
    headers: {'content-type': 'application/json'},
  );
}

Future<shelf.Response> _readyzHandler(shelf.Request request) async {
  final dbHealthy = await databaseService.healthCheck();
  final cacheHealthy = await cacheService.ping();

  if (dbHealthy && cacheHealthy) {
    return shelf.Response.ok(
      jsonEncode({'status': 'ready'}),
      headers: {'content-type': 'application/json'},
    );
  }
  return shelf.Response(503,
    body: jsonEncode({'status': 'not_ready'}),
    headers: {'content-type': 'application/json'},
  );
}

shelf.Response _jsonHandler(shelf.Request request) {
  final n = itemCount(request.url.queryParameters['n']);

  // The envelope timestamp is the only clock-dependent field and is excluded
  // from the parity hash.
  return shelf.Response.ok(
    jsonEncode({
      'items': buildItems(n),
      'count': n,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    }),
    headers: {'content-type': 'application/json'},
  );
}

Future<shelf.Response> _simpleDbHandler(shelf.Request request) async {
  final idParam = request.url.queryParameters['id'];
  if (idParam == null) {
    return shelf.Response(400,
      body: jsonEncode({'error': 'Bad Request', 'message': 'id parameter is required'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final userId = int.tryParse(idParam);
  if (userId == null) {
    return shelf.Response(400,
      body: jsonEncode({'error': 'Bad Request', 'message': 'id must be a number'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final user = await databaseService.getUser(userId);
  if (user == null) {
    return shelf.Response(404,
      body: jsonEncode({'error': 'Not Found', 'message': 'User not found'}),
      headers: {'content-type': 'application/json'},
    );
  }

  return shelf.Response.ok(
    jsonEncode(user),
    headers: {'content-type': 'application/json'},
  );
}

Future<shelf.Response> _complexDbHandler(shelf.Request request) async {
  final daysParam = request.url.queryParameters['days'];
  final days = daysParam != null ? int.tryParse(daysParam) ?? 30 : 30;

  if (days <= 0 || days > 365) {
    return shelf.Response(400,
      body: jsonEncode({'error': 'Bad Request', 'message': 'days must be between 1 and 365'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final users = await databaseService.getComplexQuery(days);

  return shelf.Response.ok(
    jsonEncode({
      'periodDays': days,
      'totalUsers': users.length,
      'data': users,
    }),
    headers: {'content-type': 'application/json'},
  );
}

Future<shelf.Response> _cacheHandler(shelf.Request request) async {
  final key = request.url.queryParameters['key'];
  if (key == null) {
    return shelf.Response(400,
      body: jsonEncode({'error': 'Bad Request', 'message': 'key parameter is required'}),
      headers: {'content-type': 'application/json'},
    );
  }


  // Check cache (hit)
  final cached = await cacheService.get(key);
  if (cached != null) {
    return shelf.Response.ok(
      jsonEncode({
        'key': key,
        'value': cached,
        'cached': true,
        'ttl': cacheTtlSeconds,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  // Cache miss — generate and store
  final value = 'benchmark_value_${key}_${DateTime.now().millisecondsSinceEpoch}';
  await cacheService.set(key, value, cacheTtlSeconds);

  return shelf.Response.ok(
    jsonEncode({
      'key': key,
      'value': value,
      'cached': false,
      'ttl': cacheTtlSeconds,
    }),
    headers: {'content-type': 'application/json'},
  );
}
