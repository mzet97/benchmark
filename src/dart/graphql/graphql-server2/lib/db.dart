import 'dart:io';

import 'package:postgres/postgres.dart';

import 'runtime.dart';

class DatabaseService {
  // A single Connection serialises every query behind one socket -- the defect
  // already fixed in Go REST (pgx.Conn) and Rust actix-web (client behind a
  // Mutex). Sized from DB_POOL_MAX like every other implementation.
  late final Pool _pool;

  Future<void> initialize() async {
    // Platform.environment, not String.fromEnvironment: the latter reads
    // compile-time -D defines, not the process environment. This service was
    // therefore connecting to localhost:5432 as user "postgres" no matter what
    // the ConfigMap said, and could never have reached the benchmark database.
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
    // unmodified, so the @name placeholders were never substituted and the
    // parameters map was never bound.
    final result = await _pool.execute(
      Sql.named(sql),
      parameters: parameters ?? {},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }
}
