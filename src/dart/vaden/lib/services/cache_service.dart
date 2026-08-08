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
    // Uri.parse keeps the userinfo percent-encoded; the Redis driver needs the
    // decoded password, so use Uri.decodeComponent explicitly. The previous
    // code sent the raw "Admin%40123"-style value to Redis and auth failed,
    // so /cache came back empty and /health reported cache:down.
    final password = uri.userInfo.isNotEmpty
        ? Uri.decodeComponent(uri.userInfo.split(':').last)
        : null;

    _connection = RedisConnection();
    _command = await _connection.connect(uri.host, uri.port);

    // Authenticate now that the connection exists. RESP3 AUTH must be the first
    // command after connect when Redis requires a password.
    if (password != null && password.isNotEmpty) {
      await _command.send_object(['AUTH', password]);
    }

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
