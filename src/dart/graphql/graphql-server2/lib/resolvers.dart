import 'db.dart';
import 'cache.dart';

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
      'version': const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'database': dbStatus,
      'cache': cacheStatus,
    };
  }

  Future<Map<String, dynamic>> resolveJsonItems(int limit) async {
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < limit; i++) {
      items.add({
        'id': i + 1,
        'uuid': 'item-${i + 1}-uuid',
        'name': 'Item ${i + 1}',
        'email': 'item${i + 1}@example.com',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'isActive': i % 2 == 0,
      });
    }
    return {
      'items': items,
      'count': items.length,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>?> resolveUser(int id) async {
    final cached = await _cache.get('user:$id');
    if (cached != null) {
      return Map<String, dynamic>.from(
        (cached is String) ? _parseJson(cached) : cached,
      );
    }

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

    await _cache.set('user:$id', user.toString(), 60);
    return user;
  }

  Future<Map<String, dynamic>> resolveComplexOrders(int days) async {
    final result = await _db.query('''
      SELECT
        u.id AS user_id,
        u.first_name || ' ' || u.last_name AS user_name,
        COUNT(o.id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0) AS total_value,
        CASE WHEN COUNT(o.id) > 0
          THEN COALESCE(SUM(o.total_amount), 0) / COUNT(o.id)
          ELSE 0
        END AS average_order_value
      FROM users u
      LEFT JOIN orders o ON o.user_id = u.id
        AND o.created_at >= NOW() - (@days || ' days')::INTERVAL
      GROUP BY u.id, u.first_name, u.last_name
      ORDER BY total_value DESC
    ''', {'days': days});

    final data = result.map((row) => {
      'userId': row['user_id'] as int,
      'userName': row['user_name'] as String,
      'totalOrders': (row['total_orders'] as BigInt).toInt(),
      'totalValue': (row['total_value'] as num).toDouble(),
      'averageOrderValue': (row['average_order_value'] as num).toDouble(),
    }).toList();

    return {
      'periodDays': days,
      'totalUsers': data.length,
      'data': data,
    };
  }

  Future<Map<String, dynamic>> resolveCache(String key) async {
    final value = await _cache.get(key);
    final ttl = await _cache.ttl(key);

    return {
      'key': key,
      'value': value?.toString() ?? '',
      'cached': value != null,
      'ttl': ttl >= 0 ? ttl : 0,
    };
  }
}

Map<String, dynamic> _parseJson(String s) {
  // Simple fallback for cached JSON parsing
  return {};
}
