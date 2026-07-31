import 'dart:io';
import 'package:redis/redis.dart';
import '../utils/logger.dart';

class CacheService {
  late final RedisConnection _connection;
  late final Command _command;
  bool _initialized = false;

  Future<void> init() async {
    final redisUrl = Platform.environment['REDIS_URL'];
    if (redisUrl == null) {
      throw Exception('REDIS_URL is required');
    }

    final uri = Uri.parse(redisUrl);
    final password = uri.userInfo.isNotEmpty ? uri.userInfo.split(':').last : null;

    _connection = RedisConnection();
    _command = await _connection.connect(uri.host, uri.port);

    _initialized = true;
    logger.info('Redis connected to ${uri.host}:${uri.port}');
  }

  Future<void> close() async {
    if (_initialized) {
      await _connection.close();
      _initialized = false;
      logger.info('Redis disconnected');
    }
  }

  Future<String?> get(String key) async {
    if (!_initialized) throw Exception('Redis not initialized');
    final result = await _command.send_object(['GET', key]);
    return result as String?;
  }

  Future<void> set(String key, String value, int ttlSeconds) async {
    if (!_initialized) throw Exception('Redis not initialized');
    await _command.send_object(['SETEX', key, ttlSeconds, value]);
  }

  Future<bool> ping() async {
    if (!_initialized) return false;
    try {
      final result = await _command.send_object(['PING']);
      return result == 'PONG';
    } catch (error) {
      logger.severe('Redis health check failed: $error');
      return false;
    }
  }
}
