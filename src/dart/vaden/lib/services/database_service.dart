import 'dart:io';
import 'package:postgres/postgres.dart';
import '../utils/logger.dart';

class DatabaseService {
  late final Connection _connection;
  bool _initialized = false;

  Future<void> init() async {
    final databaseUrl = Platform.environment['DATABASE_URL'];
    if (databaseUrl == null) {
      throw Exception('DATABASE_URL is required');
    }

    _connection = await Connection.open(
      Endpoint(
        host: Uri.parse(databaseUrl).host,
        database: Uri.parse(databaseUrl).path.substring(1),
        username: Uri.parse(databaseUrl).userInfo.split(':').first,
        password: Uri.parse(databaseUrl).userInfo.split(':').last,
        port: Uri.parse(databaseUrl).port,
      ),
      settings: ConnectionSettings(
        timeoutInterval: Duration(
          seconds: int.parse(Platform.environment['DB_TIMEOUT'] ?? '30'),
        ),
      ),
    );

    _initialized = true;
    logger.info('Database connected');
  }

  Future<void> close() async {
    if (_initialized) {
      await _connection.close();
      _initialized = false;
      logger.info('Database disconnected');
    }
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    if (!_initialized) {
      throw Exception('Database not initialized');
    }

    final query = '''
      SELECT id, email, first_name, last_name, age, created_at
      FROM users
      WHERE id = @id
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'id': userId},
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;
    return {
      'id': row[0] as int,
      'email': row[1] as String,
      'first_name': row[2] as String,
      'last_name': row[3] as String,
      'age': row[4] as int,
      'created_at': (row[5] as DateTime).toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> getComplexQuery(int days) async {
    if (!_initialized) {
      throw Exception('Database not initialized');
    }

    final query = '''
      SELECT
        u.id as user_id,
        u.first_name || ' ' || u.last_name as user_name,
        COUNT(DISTINCT o.id) as total_orders,
        COALESCE(SUM(oi.quantity * oi.price), 0) as total_value,
        COALESCE(AVG(oi.quantity * oi.price), 0) as average_value
      FROM users u
      LEFT JOIN orders o ON u.id = o.user_id
        AND o.created_at >= NOW() - INTERVAL '@days days'
        AND o.status = 'completed'
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.id IS NULL OR (o.created_at >= NOW() - INTERVAL '@days days' AND o.status = 'completed')
      GROUP BY u.id, u.first_name, u.last_name
      HAVING COUNT(DISTINCT o.id) > 0
      ORDER BY total_value DESC
      LIMIT 100
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'days': days},
    );

    return result.map((row) => {
      'user_id': row[0] as int,
      'user_name': row[1] as String,
      'total_orders': row[2] as int,
      'total_value': row[3] as double,
      'average_value': row[4] as double,
    }).toList();
  }

  Future<bool> healthCheck() async {
    if (!_initialized) {
      return false;
    }

    try {
      await _connection.execute('SELECT 1');
      return true;
    } catch (error) {
      logger.severe('Database health check failed', error);
      return false;
    }
  }
}
