import 'package:logging/logging.dart';

final logger = Logger('BenchmarkAPI');

void setupLogger() {
  Logger.root.level = Level.INFO;
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
