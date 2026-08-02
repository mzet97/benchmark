import 'dart:io';

import 'package:logging/logging.dart';

final logger = Logger('BenchmarkAPI');

// LOG_LEVEL comes from the ConfigMap and is "error" while measuring. Pinning
// INFO here meant this implementation logged where the others did not.
const _levels = <String, Level>{
  'off': Level.OFF,
  'error': Level.SEVERE,
  'severe': Level.SEVERE,
  'warn': Level.WARNING,
  'warning': Level.WARNING,
  'info': Level.INFO,
  'debug': Level.FINE,
  'trace': Level.FINEST,
};

void setupLogger() {
  final name = (Platform.environment['LOG_LEVEL'] ?? 'info').toLowerCase();
  Logger.root.level = _levels[name] ?? Level.INFO;
  Logger.root.onRecord.listen((LogRecord record) {
    print('${record.time}: ${record.level.name}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });
}
