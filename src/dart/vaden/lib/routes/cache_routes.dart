import 'package:vaden/vaden.dart';
import '../models/cache_response.dart';
import '../services/cache_service.dart';

List<Route> cacheRoutes() {
  return [
    Route.get('/cache', _cacheHandler),
  ];
}

Future<Response> _cacheHandler(Request request) async {
  final cacheService = request.context['cacheService'] as CacheService;

  final key = request.url.queryParameters['key'];
  if (key == null) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Bad Request',
        'message': 'key parameter is required',
      },
    );
  }

  final ttl = int.parse(Platform.environment['CACHE_TTL'] ?? '300');

  final cached = await cacheService.get(key);

  if (cached != null) {
    final response = CacheResponse(
      key: key,
      value: cached,
      cached: true,
      ttl: ttl,
    );

    return Response.json(
      body: response.toJson(),
    );
  }

  final value = 'cached_data_${key}_${DateTime.now().millisecondsSinceEpoch}';
  await cacheService.set(key, value, ttl);

  final response = CacheResponse(
    key: key,
    value: value,
    cached: false,
    ttl: ttl,
  );

  return Response.json(
    body: response.toJson(),
  );
}
