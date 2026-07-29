import 'dart:io';

import 'package:postgres/postgres.dart';

/// PostgreSQL connection manager for the benchmark service.
class Database {
  Connection? _connection;

  /// Connection string from environment.
  String get _connectionString =>
      Platform.environment['DATABASE_URL'] ??
      'postgres://benchmark:benchmark@localhost:5432/benchmark';

  /// Get or create the database connection.
  Future<Connection> getConnection() async {
    if (_connection == null || _connection!.isClosed) {
      final uri = Uri.parse(_connectionString);
      _connection = await Connection.open(
        Endpoint(
          host: uri.host,
          port: uri.port,
          database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'benchmark',
          username: uri.userInfo.split(':').first,
          password: uri.userInfo.contains(':')
              ? uri.userInfo.split(':').last
              : '',
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );
    }
    return _connection!;
  }

  /// Check database connectivity and return status string.
  Future<String> checkDatabase() async {
    try {
      final conn = await getConnection();
      await conn.execute(Sql.indexed('SELECT 1'));
      return 'connected';
    } catch (e) {
      return 'error: $e';
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
    }
    _connection = null;
  }
}
