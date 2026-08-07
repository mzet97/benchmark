import 'dart:io';
import 'package:postgres/postgres.dart';
import '../runtime.dart';
import '../utils/logger.dart';

class DatabaseService {
  // A single Connection serialises every /db/* request behind one socket, the
  // same defect already fixed in Go REST (pgx.Conn with no pool) and Rust
  // actix-web (one client behind a Mutex). Those numbers measured queueing,
  // not the framework. Pool is sized from DB_POOL_MAX like everyone else.
  late final Pool _pool;
  bool _initialized = false;

  Future<void> init() async {
    final databaseUrl = Platform.environment['DATABASE_URL'];
    if (databaseUrl == null) {
      throw Exception('DATABASE_URL is required');
    }

    final uri = Uri.parse(databaseUrl);
    final userInfo = uri.userInfo.split(':');

    _pool = Pool.withEndpoints(
      [
        Endpoint(
          host: uri.host,
          database: uri.path.substring(1),
          username: userInfo.first,
          password: userInfo.length > 1 ? userInfo.last : '',
          port: uri.port,
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: dbPoolPerWorker(),
        connectTimeout: Duration(seconds: int.parse(Platform.environment['DB_TIMEOUT'] ?? '30')),
        // The other four Dart implementations already disable TLS. Leaving it
        // on the driver default here would have put a handshake and per-query
        // encryption on this implementation alone.
        sslMode: SslMode.disable,
      ),
    );

    _initialized = true;
    logger.info('Database pool opened against ${uri.host}:${uri.port}');
  }

  Future<void> close() async {
    if (_initialized) {
      await _pool.close();
      _initialized = false;
      logger.info('Database disconnected');
    }
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    if (!_initialized) {
      throw Exception('Database not initialized');
    }

    final result = await _pool.execute(
      Sql.named('SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = @id'),
      parameters: {'id': userId},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'id': row[0] as int,
      'email': row[1] as String,
      'firstName': row[2] as String,
      'lastName': row[3] as String,
      'age': row[4] as int,
      'createdAt': (row[5] as DateTime).toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> getComplexQuery(int days) async {
    if (!_initialized) {
      throw Exception('Database not initialized');
    }

    final query = '''
      -- Normative SQL, see contracts/rest/canonical-payloads.md. The previous
      -- query joined order_items, aggregated quantity*price and ordered without
      -- a tiebreak, so it ran a heavier query than the other implementations and
      -- its rows came back in arbitrary order among equal values.
      SELECT
          u.id AS "userId",
          u.first_name || ' ' || u.last_name AS "userName",
          COUNT(o.id) AS "totalOrders",
          COALESCE(SUM(o.total_amount), 0) AS "totalValue",
          COALESCE(AVG(o.total_amount), 0) AS "averageOrderValue"
      FROM users u
      INNER JOIN orders o ON u.id = o.user_id
          WHERE o.created_at >= NOW() - INTERVAL '1 day' * \$1
      GROUP BY u.id, u.first_name, u.last_name
      ORDER BY "totalOrders" DESC, u.id
      LIMIT 100
    ''';

    final result = await _pool.execute(query, parameters: [days]);

    return result.map((row) => {
      'userId': row[0] as int,
      'userName': row[1] as String,
      'totalOrders': asInt(row[2]),
      'totalValue': asDouble(row[3]),
      'averageOrderValue': asDouble(row[4]),
    }).toList();
  }

  Future<bool> healthCheck() async {
    if (!_initialized) return false;
    try {
      await _pool.execute('SELECT 1');
      return true;
    } catch (error) {
      logger.severe('Database health check failed: $error');
      return false;
    }
  }
}
