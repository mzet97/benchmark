import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/services/database_service.dart';
import '../lib/services/cache_service.dart';

final databaseService = DatabaseService();
final cacheService = CacheService();

Future<void> main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '3000');
  final host = Platform.environment['HOST'] ?? '0.0.0.0';

  // Initialize services
  await databaseService.init();
  await cacheService.init();

  final router = Router();

  // Root
  router.get('/', (Request request) {
    return Response.ok(
      _jsonEncode({
        'name': 'Benchmark API - Dart Shelf',
        'version': '1.0.0',
        'runtime': 'Dart',
        'framework': 'Shelf',
        'database': 'PostgreSQL',
        'cache': 'Redis',
        'status': 'running',
      }),
      headers: _jsonHeaders,
    );
  });

  // Health
  router.get('/health', (Request request) async {
    final dbOk = await databaseService.healthCheck();
    final cacheOk = await cacheService.ping();
    final healthy = dbOk && cacheOk;
    return Response.ok(
      _jsonEncode({
        'status': healthy ? 'healthy' : 'unhealthy',
        'version': '1.0.0',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'database': dbOk ? 'connected' : 'disconnected',
        'cache': cacheOk ? 'connected' : 'disconnected',
      }),
      headers: _jsonHeaders,
      status: healthy ? 200 : 503,
    );
  });

  // Healthz
  router.get('/healthz', (Request request) {
    return Response.ok(_jsonEncode({'status': 'ok'}), headers: _jsonHeaders);
  });

  // JSON
  router.get('/json', (Request request) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final items = List.generate(1000, (i) => {
      'id': i + 1,
      'name': 'Item ${i + 1}',
      'description': 'This is item number ${i + 1}',
      'timestamp': timestamp,
    });
    return Response.ok(
      _jsonEncode({'items': items, 'count': 1000, 'timestamp': timestamp}),
      headers: _jsonHeaders,
    );
  });

  // DB Simple
  router.get('/db/simple', (Request request) async {
    final idParam = request.url.queryParameters['id'];
    if (idParam == null) {
      return Response.ok(_jsonEncode({'error': 'Invalid id parameter'}), headers: _jsonHeaders, status: 400);
    }
    final userId = int.tryParse(idParam);
    if (userId == null || userId <= 0) {
      return Response.ok(_jsonEncode({'error': 'Invalid id parameter'}), headers: _jsonHeaders, status: 400);
    }
    final user = await databaseService.getUser(userId);
    if (user == null) {
      return Response.ok(_jsonEncode({'error': 'User with id $userId not found'}), headers: _jsonHeaders, status: 404);
    }
    return Response.ok(_jsonEncode(user), headers: _jsonHeaders);
  });

  // DB Complex
  router.get('/db/complex', (Request request) async {
    final daysParam = request.url.queryParameters['days'];
    final days = daysParam != null ? int.tryParse(daysParam) ?? 30 : 30;
    if (days <= 0 || days > 365) {
      return Response.ok(_jsonEncode({'error': 'Days must be between 1 and 365'}), headers: _jsonHeaders, status: 400);
    }
    final results = await databaseService.getComplexQuery(days);
    return Response.ok(
      _jsonEncode({
        'period_days': days,
        'total_users': results.length,
        'data': results,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }),
      headers: _jsonHeaders,
    );
  });

  // Cache
  router.get('/cache', (Request request) async {
    final key = request.url.queryParameters['key'];
    if (key == null || key.isEmpty) {
      return Response.ok(_jsonEncode({'error': 'Key parameter is required'}), headers: _jsonHeaders, status: 400);
    }
    final cached = await cacheService.get(key);
    if (cached != null) {
      return Response.ok(
        _jsonEncode({'key': key, 'value': cached, 'cached': true, 'timestamp': DateTime.now().toUtc().toIso8601String()}),
        headers: _jsonHeaders,
      );
    }
    final value = 'Cached value for $key at ${DateTime.now().toUtc().toIso8601String()}';
    await cacheService.set(key, value, 300);
    return Response.ok(
      _jsonEncode({'key': key, 'value': value, 'cached': false, 'timestamp': DateTime.now().toUtc().toIso8601String()}),
      headers: _jsonHeaders,
    );
  });

  // CORS middleware
  final handler = const shelf.Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(shelf.logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, host, port);
  print('🚀 Dart Shelf server listening on http://${server.address.host}:${server.port}');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('Shutting down...');
    await databaseService.close();
    await cacheService.close();
    await server.close(force: true);
    exit(0);
  });
}

const _jsonHeaders = {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'};

String _jsonEncode(Object? object) {
  // Simple JSON encoding without dart:convert dependency
  if (object is Map) {
    final entries = object.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}').join(',');
    return '{$entries}';
  }
  if (object is List) {
    final items = object.map((e) => _jsonEncode(e)).join(',');
    return '[$items]';
  }
  if (object is String) return '"${object.replaceAll('"', '\\"')}"';
  if (object is num || object is bool) return '$object';
  if (object == null) return 'null';
  return '"$object"';
}

shelf.Middleware _corsMiddleware() {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      if (request.method == 'OPTIONS') {
        return shelf.Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        });
      }
      final response = await innerHandler(request);
      return response.change(headers: {'Access-Control-Allow-Origin': '*'});
    };
  };
}
