import 'dart:io';
import 'package:redis/redis.dart';

class CacheService {
  late final RedisConnection _connection;
  late final Command _command;

  Future<void> initialize() async {
    final host = Platform.environment['REDIS_HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['REDIS_PORT'] ?? '6379');

    _connection = RedisConnection();
    _command = await _connection.connect(host, port);
  }

  Future<void> ping() async {
    await _command.send('PING');
  }

  Future<dynamic> get(String key) async {
    return await _command.send('GET', key);
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
