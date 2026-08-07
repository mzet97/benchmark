import 'dart:io';

import 'package:redis/redis.dart';

/// Redis connection manager for the benchmark service.
class Cache {
  Command? _command;
  RedisConnection? _connection;

  /// Redis URL from environment.
  String get _redisUrl =>
      Platform.environment['REDIS_URL'] ?? 'redis://localhost:6379';

  /// Get or create the Redis command.
  Future<Command> getCommand() async {
    if (_command == null) {
      _connection = RedisConnection();
      final uri = Uri.parse(_redisUrl);
      _command = await _connection!.connect(
        uri.host,
        uri.port,
      );
    }
    return _command!;
  }

  /// Check Redis connectivity and return status string.
  Future<String> checkCache() async {
    try {
      final cmd = await getCommand();
      await cmd.send_object(['PING']);
      return 'connected';
    } catch (e) {
      return 'error: $e';
    }
  }

  /// Close the Redis connection.
  Future<void> close() async {
    if (_connection != null) {
      _connection!.close();
    }
    _connection = null;
    _command = null;
  }
}
