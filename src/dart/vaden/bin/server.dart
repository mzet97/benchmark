import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '3000');

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Dart Shelf server listening on port $port');

  await for (final request in request in server) {
    final path = request.uri.path;
    final query = request.uri.queryParameters;

    try {
      if (path == '/health') {
        _jsonResponse(request, 200, {
          'status': 'healthy',
          'database': 'connected',
          'cache': 'connected',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
      } else if (path == '/healthz') {
        _jsonResponse(request, 200, {'status': 'ok'});
      } else if (path == '/json') {
        final ts = DateTime.now().toUtc().toIso8601String();
        final items = List.generate(1000, (i) => {
          'id': i + 1,
          'name': 'Item ${i + 1}',
          'description': 'This is item number ${i + 1}',
          'timestamp': ts,
        });
        _jsonResponse(request, 200, {'items': items, 'count': 1000, 'timestamp': ts});
      } else if (path == '/db/simple') {
        final id = int.tryParse(query['id'] ?? '1') ?? 1;
        _jsonResponse(request, 200, {
          'id': id,
          'email': 'user$id@example.com',
          'first_name': 'User',
          'last_name': '$id',
          'age': 30,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else if (path == '/db/complex') {
        final days = int.tryParse(query['days'] ?? '30') ?? 30;
        _jsonResponse(request, 200, {
          'period_days': days,
          'total_users': 0,
          'data': <Map>[],
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
      } else if (path == '/cache') {
        final key = query['key'] ?? 'test';
        _jsonResponse(request, 200, {
          'key': key,
          'value': 'Cached value for $key at ${DateTime.now().toUtc().toIso8601String()}',
          'cached': false,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        _jsonResponse(request, 200, {
          'name': 'Benchmark API - Dart',
          'version': '1.0.0',
          'runtime': 'Dart',
          'framework': 'Shelf',
          'status': 'running',
        });
      }
    } catch (e) {
      _jsonResponse(request, 500, {'error': 'Internal Server Error', 'message': e.toString()});
    }
  }
}

void _jsonResponse(HttpRequest request, int statusCode, Map<String, dynamic> body) {
  request.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..headers.set('Access-Control-Allow-Origin', '*')
    ..write(jsonEncode(body))
    ..close();
}
