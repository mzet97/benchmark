import 'package:vaden/vaden.dart';
import '../models/health_status.dart';
import '../services/database_service.dart';
import '../services/cache_service.dart';
import '../utils/logger.dart';

List<Route> healthRoutes() {
  return [
    Route.get('/health', _healthHandler),
    Route.get('/healthz', _healthzHandler),
  ];
}

Future<Response> _healthHandler(Request request) async {
  final databaseService = request.context['databaseService'] as DatabaseService;
  final cacheService = request.context['cacheService'] as CacheService;

  final dbHealthy = await databaseService.healthCheck();
  final cacheHealthy = await cacheService.ping();

  final health = HealthStatus(
    status: dbHealthy && cacheHealthy ? 'healthy' : 'unhealthy',
    version: '1.0.0',
    timestamp: DateTime.now(),
    database: dbHealthy ? 'healthy' : 'unhealthy',
    cache: cacheHealthy ? 'healthy' : 'unhealthy',
  );

  final statusCode = dbHealthy && cacheHealthy ? 200 : 503;

  return Response.json(
    statusCode: statusCode,
    body: health.toJson(),
  );
}

Future<Response> _healthzHandler(Request request) {
  return Response.json(body: {'status': 'ok'});
}
