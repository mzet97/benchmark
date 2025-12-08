import 'package:postgres/postgres.dart';
import '../models/models.dart';
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

  Future<User?> getUser(int userId) async {
    if (!_initialized) {
      throw Exception('Database not initialized');
    }

    final query = '''
      SELECT id, email, first_name, last_name, created_at
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
    return User(
      id: row[0] as int,
      email: row[1] as String,
      firstName: row[2] as String,
      lastName: row[3] as String,
      createdAt: row[4] as DateTime,
    );
  }

  Future<List<Map<String, dynamic>>> getComplexOrders(int days) async {
    if (!_initialized) {
      throw Exception('Database not initialized');
    }

    final query = '''
      SELECT
        o.id as order_id,
        o.user_id,
        u.email as user_email,
        o.total_amount,
        o.created_at,
        COUNT(oi.id) as items_count
      FROM orders o
      JOIN users u ON o.user_id = u.id
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.created_at >= NOW() - INTERVAL '@days days'
      GROUP BY o.id, u.email
      ORDER BY o.created_at DESC
      LIMIT 100
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'days': days},
    );

    return result.map((row) => {
      'order_id': row[0] as int,
      'user_id': row[1] as int,
      'user_email': row[2] as String,
      'total_amount': row[3] as double,
      'created_at': row[4] as DateTime,
      'items_count': row[5] as int,
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
