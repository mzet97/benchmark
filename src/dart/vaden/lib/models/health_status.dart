class HealthStatus {
  final String status;
  final String version;
  final String timestamp;
  final String database;
  final String cache;

  const HealthStatus({
    required this.status,
    required this.version,
    required this.timestamp,
    required this.database,
    required this.cache,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'version': version,
      'timestamp': timestamp,
      'database': database,
      'cache': cache,
    };
  }
}
