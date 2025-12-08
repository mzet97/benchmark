import 'package:vaden/vaden.dart';

Middleware corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final response = await handler(request);

      response.headers['Access-Control-Allow-Origin'] = '*';
      response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
      response.headers['Access-Control-Allow-Credentials'] = 'true';

      if (request.method == 'OPTIONS') {
        return Response(statusCode: 204);
      }

      return response;
    };
  };
}

Middleware loggingMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final start = DateTime.now();
      final response = await handler(request);
      final duration = DateTime.now().difference(start);

      logger.info('Request processed', {
        'method': request.method,
        'url': request.url.toString(),
        'status': response.statusCode,
        'duration': '${duration.inMilliseconds}ms',
      });

      return response;
    };
  };
}

Middleware errorMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      try {
        return await handler(request);
      } catch (error, stackTrace) {
        logger.severe('Unhandled error', error, stackTrace);

        return Response.json(
          statusCode: 500,
          body: {
            'error': 'Internal server error',
            'message': Platform.environment['DEBUG'] == 'true'
                ? error.toString()
                : 'An error occurred',
          },
        );
      }
    };
  };
}
