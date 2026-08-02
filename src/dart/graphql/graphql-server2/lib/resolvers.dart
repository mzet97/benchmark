import 'dart:io';

import 'db.dart';
import 'cache.dart';
import 'runtime.dart';
import 'package:graphql_server2_benchmark/canonical.dart';

class Resolvers {
  late final DatabaseService _db;
  late final CacheService _cache;

  Resolvers();

  Future<void> initialize() async {
    _db = DatabaseService();
    _cache = CacheService();
    await _db.initialize();
    await _cache.initialize();
  }

  Future<Map<String, dynamic>> resolveHealth() async {
    var dbStatus = 'ok';
    var cacheStatus = 'ok';

    try {
      await _db.ping();
    } catch (_) {
      dbStatus = 'error';
    }

    try {
      await _cache.ping();
    } catch (_) {
      cacheStatus = 'error';
    }

    return {
      'status': 'ok',
      'version': Platform.environment['APP_VERSION'] ?? '1.0.0',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'database': dbStatus,
      'cache': cacheStatus,
    };
  }

  Future<Map<String, dynamic>> resolveJsonItems(int limit) async {
    // The previous version used a 'item-<n>-uuid' string that is not a UUID,
    // numbered items from 1, used @example.com and stamped the clock into
    // createdAt. See contracts/rest/canonical-payloads.md.
    final count = itemCount(limit);
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      items.add({
        'id': i,
        'uuid': canonicalUuid(i),
        'name': canonicalName(i),
        'email': canonicalEmail(i),
        'createdAt': canonicalCreatedAt,
        'isActive': canonicalIsActive(i),
      });
    }
    return {
      'items': items,
      'count': items.length,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>?> resolveUser(int id) async {
    // This used to write the user into Redis with Map.toString() and, on the
    // next call, read it back through a _parseJson stub that returned {} --
    // so from the second request onwards this resolver answered with an empty
    // object and never touched PostgreSQL. No other implementation caches
    // /db/simple; the contract is a database read.
    final result = await _db.query(
      'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = @id',
      {'id': id},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final user = {
      'id': row['id'] as int,
      'email': row['email'] as String,
      'firstName': row['first_name'] as String,
      'lastName': row['last_name'] as String,
      'age': row['age'] as int,
      'createdAt': (row['created_at'] as DateTime).toIso8601String(),
    };

    return user;
  }

  Future<Map<String, dynamic>> resolveComplexOrders(int days) async {
    // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
    // query used a LEFT JOIN, computed the average by hand, had no LIMIT and
    // no tiebreak in the ORDER BY, so the row order was arbitrary among equal
    // values and the response was not reproducible between runs.
    final result = await _db.query('''
      SELECT
        u.id AS user_id,
        u.first_name || ' ' || u.last_name AS user_name,
        COUNT(o.id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0) AS total_value,
        COALESCE(AVG(o.total_amount), 0) AS average_order_value
      FROM users u
      INNER JOIN orders o ON u.id = o.user_id
        WHERE o.created_at >= NOW() - INTERVAL '1 day' * @days
      GROUP BY u.id, u.first_name, u.last_name
      ORDER BY total_orders DESC, u.id
      LIMIT 100
    ''', {'days': days});

    final data = result.map((row) => {
      'userId': row['user_id'] as int,
      'userName': row['user_name'] as String,
      'totalOrders': asInt(row['total_orders']),
      'totalValue': asDouble(row['total_value']),
      'averageOrderValue': asDouble(row['average_order_value']),
    }).toList();

    return {
      'periodDays': days,
      'totalUsers': data.length,
      'data': data,
    };
  }

  Future<Map<String, dynamic>> resolveCache(String key) async {
    final cached = await _cache.get(key);
    if (cached != null) {
      final ttl = await _cache.ttl(key);
      return {
        'key': key,
        'value': cached.toString(),
        'cached': true,
        'ttl': ttl >= 0 ? ttl : 0,
      };
    }

    // On a miss every other implementation writes the value back with
    // CACHE_TTL; this one never did, so its key stayed empty and it reported
    // cached: false on every request while the others reported a hit.
    final value = 'benchmark_value_${key}_'
        '${DateTime.now().millisecondsSinceEpoch}';
    await _cache.set(key, value, _cacheTtlSeconds);

    return {
      'key': key,
      'value': value,
      'cached': false,
      'ttl': _cacheTtlSeconds,
    };
  }
}

/// Part of the response contract; must match what is written to Redis.
/// See contracts/rest/canonical-payloads.md.
final int _cacheTtlSeconds =
    int.tryParse(Platform.environment['CACHE_TTL'] ?? '') ?? 300;
