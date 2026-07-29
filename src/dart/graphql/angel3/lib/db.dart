import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseService {
  late final Connection _connection;

  Future<void> initialize() async {
    final host = Platform.environment['DB_HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final username = Platform.environment['DB_USER'] ?? 'benchmark';
    final password = Platform.environment['DB_PASSWORD'] ?? 'benchmark';
    final database = Platform.environment['DB_NAME'] ?? 'benchmark';

    _connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  Future<void> ping() async {
    await _connection.execute(Sql.select('SELECT 1'));
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    Map<String, dynamic>? parameters,
  ]) async {
    final result = await _connection.execute(
      Sql(sql),
      parameters: parameters ?? {},
    );
    return result.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    final results = await query(
      'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = @id',
      {'id': id},
    );
    if (results.isEmpty) return null;
    final row = results.first;
    return {
      'id': row['id'] as int,
      'email': row['email'] as String,
      'firstName': row['first_name'] as String,
      'lastName': row['last_name'] as String,
      'age': row['age'] as int,
      'createdAt': (row['created_at'] as DateTime).toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> getComplexOrders(int days) async {
    final results = await query('''
      SELECT
        u.id AS user_id,
        u.first_name || ' ' || u.last_name AS user_name,
        COUNT(o.id) AS total_orders,
        COALESCE(SUM(o.amount), 0) AS total_value,
        COALESCE(AVG(o.amount), 0) AS average_order_value
      FROM users u
      LEFT JOIN orders o ON o.user_id = u.id
        AND o.created_at >= NOW() - (@days || ' days')::INTERVAL
      GROUP BY u.id, u.first_name, u.last_name
      ORDER BY total_value DESC
    ''', {'days': days});

    return results.map((row) => {
      'userId': row['user_id'] as int,
      'userName': row['user_name'] as String,
      'totalOrders': (row['total_orders'] as BigInt).toInt(),
      'totalValue': (row['total_value'] as num).toDouble(),
      'averageOrderValue': (row['average_order_value'] as num).toDouble(),
    }).toList();
  }
}
