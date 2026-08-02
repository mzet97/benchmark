import 'dart:math';
import 'package:benchmark_grpc_dart/canonical.dart';

import 'package:grpc/grpc.dart';

import 'benchmark.pbgrpc.dart';
import 'cache.dart';
import 'db.dart';

/// Implementation of BenchmarkService for the benchmark suite.
class BenchmarkServiceImpl extends BenchmarkServiceBase {
  static const String _version = '1.0.0';
  final Database _db;
  final Cache _cache;

  BenchmarkServiceImpl(this._db, this._cache);

  @override
  Future<HealthResponse> health(
      ServiceCall call, HealthRequest request) async {
    final dbStatus = await _db.checkDatabase();
    final cacheStatus = await _cache.checkCache();
    return HealthResponse()
      ..status = 'ok'
      ..version = _version
      ..timestamp = DateTime.now().toUtc().toIso8601String()
      ..database = dbStatus
      ..cache = cacheStatus;
  }

  @override
  Future<JsonItemsResponse> getJsonItems(
      ServiceCall call, JsonItemsRequest request) async {
    // The previous version numbered items from 1, drew a UUID from a seeded
    // Random and named them "user_3" at user_3@benchmark.dev.
    // See contracts/rest/canonical-payloads.md.
    final count = itemCount(request.limit);
    final items = <JsonItem>[];

    for (var i = 0; i < count; i++) {
      items.add(JsonItem()
        ..id = i
        ..uuid = canonicalUuid(i)
        ..name = canonicalName(i)
        ..email = canonicalEmail(i)
        ..createdAt = canonicalCreatedAt
        ..isActive = canonicalIsActive(i));
    }

    return JsonItemsResponse()
      ..items.addAll(items)
      ..count = items.length
      ..timestamp = DateTime.now().toUtc().toIso8601String();
  }

  @override
  Future<UserResponse> getUser(
      ServiceCall call, GetUserRequest request) async {
    final conn = await _db.getConnection();
    final results = await conn.execute(
      Sql.indexed(
        'SELECT id, email, first_name, last_name, age, created_at '
        'FROM users WHERE id = \$1',
      ),
      parameters: [request.id],
      //ResultLimit: 1,
    );

    if (results.isEmpty) {
      throw GrpcError.notFound('User ${request.id} not found');
    }

    final row = results.first;
    return UserResponse()
      ..id = row[0] as int
      ..email = row[1] as String
      ..firstName = row[2] as String
      ..lastName = row[3] as String
      ..age = row[4] as int
      ..createdAt = row[5].toString();
  }

  @override
  Future<ComplexOrdersResponse> getComplexOrders(
      ServiceCall call, ComplexOrdersRequest request) async {
    final days = request.days > 0 ? request.days : 30;
    final conn = await _db.getConnection();
    final results = await conn.execute(
      Sql.indexed(
        'SELECT '
        '  u.id AS user_id, '
        '  u.first_name || \' \' || u.last_name AS user_name, '
        '  COUNT(o.id) AS total_orders, '
        '  COALESCE(SUM(o.total), 0) AS total_value, '
        '  COALESCE(AVG(o.total), 0) AS average_order_value '
        'FROM users u '
        'LEFT JOIN orders o ON u.id = o.user_id '
        '  AND o.created_at >= NOW() - INTERVAL \'$days days\' '
        'GROUP BY u.id, u.first_name, u.last_name '
        'ORDER BY total_value DESC',
      ),
    );

    final data = <UserOrderStats>[];
    for (final row in results) {
      data.add(UserOrderStats()
        ..userId = row[0] as int
        ..userName = row[1] as String
        ..totalOrders = (row[2] as int)
        ..totalValue = (row[3] as num).toDouble()
        ..averageOrderValue = (row[4] as num).toDouble());
    }

    return ComplexOrdersResponse()
      ..periodDays = days
      ..totalUsers = data.length
      ..data.addAll(data);
  }

  @override
  Future<CacheResponse> getCacheValue(
      ServiceCall call, CacheRequest request) async {
    final cmd = await _cache.getCommand();

    // Try cache hit
    final cached = await cmd.send(['GET', request.key]);
    if (cached != null && cached is String && cached.isNotEmpty) {
      final ttlRaw = await cmd.send(['TTL', request.key]);
      final ttl = (ttlRaw is int) ? (ttlRaw >= 0 ? ttlRaw : 0) : 0;
      return CacheResponse()
        ..key = request.key
        ..value = cached
        ..cached = true
        ..ttl = ttl
        ..timestamp = DateTime.now().toUtc().toIso8601String();
    }

    // Cache miss: generate value and store
    final rng = Random();
    final value = 'value_for_${request.key}_${_generateUuid(rng)}';
    await cmd.send(['SETEX', request.key, '3600', value]);

    return CacheResponse()
      ..key = request.key
      ..value = value
      ..cached = false
      ..ttl = 3600
      ..timestamp = DateTime.now().toUtc().toIso8601String();
  }

  /// Generate a simple UUID-like string using the given random source.
  String _generateUuid(Random rng) {
    const hex = '0123456789abcdef';
    final buf = StringBuffer();
    for (var i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        buf.write('-');
      } else {
        buf.write(hex[rng.nextInt(16)]);
      }
    }
    return buf.toString();
  }
}
