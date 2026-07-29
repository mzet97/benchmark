import 'package:postgres/postgres.dart';

class DatabaseService {
  late final Connection _connection;

  Future<void> initialize() async {
    final host = const String.fromEnvironment('DB_HOST', defaultValue: 'localhost');
    final port = int.parse(
      const String.fromEnvironment('DB_PORT', defaultValue: '5432'),
    );
    final username = const String.fromEnvironment('DB_USER', defaultValue: 'postgres');
    final password = const String.fromEnvironment('DB_PASSWORD', defaultValue: 'postgres');
    final database = const String.fromEnvironment('DB_NAME', defaultValue: 'benchmark');

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
}
