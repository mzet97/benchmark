import 'dart:io';
import 'package:postgres/postgres.dart';

import 'runtime.dart';

class DatabaseService {
  // A single Connection serialises every query behind one socket -- the defect
  // already fixed in Go REST (pgx.Conn) and Rust actix-web (client behind a
  // Mutex). Sized from DB_POOL_MAX like every other implementation.
  late final Pool _pool;

  Future<void> initialize() async {
    final host = Platform.environment['DB_HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final username = Platform.environment['DB_USER'] ?? 'benchmark';
    final password = Platform.environment['DB_PASSWORD'] ?? 'benchmark';
    final database = Platform.environment['DB_NAME'] ?? 'benchmark';

    _pool = Pool.withEndpoints(
      [
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: dbPoolPerWorker(),
        sslMode: SslMode.disable,
      ),
    );
  }

  Future<void> close() async {
    await _pool.close();
  }

  Future<void> ping() async {
    await _pool.execute('SELECT 1');
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    Map<String, dynamic>? parameters,
  ]) async {
    // Sql.named, not Sql(): the default constructor sends the statement
    // unmodified, so the @name placeholders below were never substituted and
    // the parameters map was never bound.
    final result = await _pool.execute(
      Sql.named(sql),
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
    // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
    // query aggregated o.amount -- a column the schema does not have, so it
    // failed at runtime -- with a LEFT JOIN, no LIMIT and no tiebreak in the
    // ORDER BY, which made the row order arbitrary among equal values.
    final results = await query('''
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

    return results.map((row) => {
      'userId': row['user_id'] as int,
      'userName': row['user_name'] as String,
      'totalOrders': asInt(row['total_orders']),
      'totalValue': asDouble(row['total_value']),
      'averageOrderValue': asDouble(row['average_order_value']),
    }).toList();
  }
}
