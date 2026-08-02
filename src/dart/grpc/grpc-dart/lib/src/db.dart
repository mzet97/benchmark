import 'dart:io';

import 'package:postgres/postgres.dart';

import 'runtime.dart';

/// PostgreSQL access for the benchmark service.
///
/// This was a single lazily-opened Connection, so every /db/* call in the
/// service serialised behind one socket -- the same defect already fixed in Go
/// REST (pgx.Conn with no pool) and Rust actix-web (one client behind a
/// Mutex). Those numbers measured queueing, not the framework.
class Database {
  Pool? _pool;

  /// Connection string from environment.
  String get _connectionString =>
      Platform.environment['DATABASE_URL'] ??
      'postgres://benchmark:benchmark@localhost:5432/benchmark';

  /// Get or create the connection pool. Pool implements Session, so callers
  /// use it exactly like a Connection.
  Session session() {
    final pool = _pool;
    if (pool != null) return pool;

    final uri = Uri.parse(_connectionString);
    return _pool = Pool.withEndpoints(
      [
        Endpoint(
          host: uri.host,
          port: uri.port,
          database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'benchmark',
          username: uri.userInfo.split(':').first,
          password: uri.userInfo.contains(':')
              ? uri.userInfo.split(':').last
              : '',
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: dbPoolPerWorker(),
        sslMode: SslMode.disable,
      ),
    );
  }

  /// Check database connectivity and return status string.
  Future<String> checkDatabase() async {
    try {
      await session().execute(Sql.indexed('SELECT 1'));
      return 'connected';
    } catch (e) {
      return 'error: $e';
    }
  }

  /// Close the pool.
  Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}
