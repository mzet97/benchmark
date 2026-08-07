import 'dart:io';

import 'package:benchmark_grpc_dart/canonical.dart';

import 'package:grpc/grpc.dart';
import 'package:postgres/postgres.dart';

import 'benchmark.pbgrpc.dart';
import 'cache.dart';
import 'db.dart';
import 'runtime.dart';

/// Implementation of BenchmarkService for the benchmark suite.
class BenchmarkServiceImpl extends BenchmarkServiceBase {
  static const String _version = '1.0.0';

  /// Part of the response contract; must match what is written to Redis.
  /// See contracts/rest/canonical-payloads.md.
  static final int _cacheTtlSeconds =
      int.tryParse(Platform.environment['CACHE_TTL'] ?? '') ?? 300;
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
    final results = await _db.session().execute(
      Sql.indexed(
        'SELECT id, email, first_name, last_name, age, created_at '
        'FROM users WHERE id = \$1',
      ),
      parameters: [request.id],
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
    // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
    // query aggregated o.total -- a column the schema does not have, so it
    // failed at runtime -- interpolated the interval straight into the
    // statement, joined with LEFT, had no LIMIT and no tiebreak in the
    // ORDER BY.
    final results = await _db.session().execute(
      Sql.indexed(
        'SELECT '
        '  u.id AS user_id, '
        '  u.first_name || \' \' || u.last_name AS user_name, '
        '  COUNT(o.id) AS total_orders, '
        '  COALESCE(SUM(o.total_amount), 0) AS total_value, '
        '  COALESCE(AVG(o.total_amount), 0) AS average_order_value '
        'FROM users u '
        'INNER JOIN orders o ON u.id = o.user_id '
        '  WHERE o.created_at >= NOW() - INTERVAL \'1 day\' * \$1 '
        'GROUP BY u.id, u.first_name, u.last_name '
        'ORDER BY total_orders DESC, u.id '
        'LIMIT 100',
      ),
      parameters: [days],
    );

    final data = <UserOrderStats>[];
    for (final row in results) {
      data.add(UserOrderStats()
        ..userId = row[0] as int
        ..userName = row[1] as String
        ..totalOrders = asInt(row[2])
        ..totalValue = asDouble(row[3])
        ..averageOrderValue = asDouble(row[4]));
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
    final cached = await cmd.send_object(['GET', request.key]);
    if (cached != null && cached is String && cached.isNotEmpty) {
      final ttlRaw = await cmd.send_object(['TTL', request.key]);
      final ttl = (ttlRaw is int) ? (ttlRaw >= 0 ? ttlRaw : 0) : 0;
      return CacheResponse()
        ..key = request.key
        ..value = cached
        ..cached = true
        ..ttl = ttl
        ..timestamp = DateTime.now().toUtc().toIso8601String();
    }

    // Cache miss: generate value and store. The TTL is CACHE_TTL (300s), not
    // the 3600 hardcoded here before: over a 5x60s run a 300s key expires and
    // a 3600s one does not, so this implementation was serving hits where the
    // others took a miss.
    final value = 'benchmark_value_${request.key}_'
        '${DateTime.now().millisecondsSinceEpoch}';
    await cmd.send_object(['SETEX', request.key, '$_cacheTtlSeconds', value]);

    return CacheResponse()
      ..key = request.key
      ..value = value
      ..cached = false
      ..ttl = _cacheTtlSeconds
      ..timestamp = DateTime.now().toUtc().toIso8601String();
  }
}
