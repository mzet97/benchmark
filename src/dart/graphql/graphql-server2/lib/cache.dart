import 'dart:io';

import 'package:redis/redis.dart';

class CacheService {
  late final RedisConnection _connection;
  late final Command _command;

  Future<void> initialize() async {
    // Platform.environment, not String.fromEnvironment: the latter reads
    // compile-time -D defines, so REDIS_URL from the ConfigMap never arrived
    // and this service always talked to localhost.
    final redisUrl =
        Platform.environment['REDIS_URL'] ?? 'redis://localhost:6379';

    final uri = Uri.parse(redisUrl);
    _connection = RedisConnection();
    _command = await _connection.connect(uri.host, uri.port);
  }

  Future<void> ping() async {
    await _command.send('PING');
  }

  Future<dynamic> get(String key) async {
    final result = await _command.send('GET', key);
    return result;
  }

  Future<void> set(String key, dynamic value, int ttlSeconds) async {
    await _command.send('SET', key, value.toString(), 'EX', ttlSeconds.toString());
  }

  Future<int> ttl(String key) async {
    final result = await _command.send('TTL', key);
    if (result is int) return result;
    return int.tryParse(result.toString()) ?? -2;
  }
}
