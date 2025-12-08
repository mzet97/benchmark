import 'dart:io';
import 'package:vaden/vaden.dart';
import 'routes/routes.dart';
import 'services/database_service.dart';
import 'services/cache_service.dart';
import 'utils/logger.dart';

class Server {
  late final VadenServer _server;
  late final DatabaseService _databaseService;
  late final CacheService _cacheService;

  Future<void> start() async {
    // Initialize services
    logger.info('Initializing services...');

    _databaseService = DatabaseService();
    await _databaseService.init();

    _cacheService = CacheService();
    await _cacheService.init();

    logger.info('Services initialized successfully');

    // Create server
    final port = int.parse(Platform.environment['PORT'] ?? '3000');
    final host = Platform.environment['HOST'] ?? '0.0.0.0';

    _server = VadenServer(
      port: port,
      host: host,
      logger: logger,
    );

    // Add middleware
    _server.addMiddleware(corsMiddleware());
    _server.addMiddleware(loggingMiddleware());

    // Add routes
    _server.addRoutes(healthRoutes());
    _server.addRoutes(jsonRoutes());
    _server.addRoutes(databaseRoutes());
    _server.addRoutes(cacheRoutes());

    // Add error handler
    _server.addErrorHandler(errorMiddleware());

    logger.info('Starting Benchmark API (Dart + Vaden)...');
    logger.info('Server listening on http://$host:$port');

    await _server.start();

    // Setup graceful shutdown
    final signals = <ProcessSignal>[];
    if (!Platform.isWindows) {
      signals.addAll([ProcessSignal.sigint, ProcessSignal.sigterm]);
    } else {
      signals.add(ProcessSignal.sigterm);
    }

    for (final signal in signals) {
      signal.watch().listen((_) async {
        logger.info('Received shutdown signal');
        await shutdown();
        exit(0);
      });
    }
  }

  Future<void> shutdown() async {
    logger.info('Shutting down server...');

    try {
      await _databaseService.close();
      await _cacheService.close();
      await _server.stop();
      logger.info('Server shutdown complete');
    } catch (error, stackTrace) {
      logger.severe('Error during shutdown', error, stackTrace);
    }
  }
}
