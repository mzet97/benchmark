import 'package:json_annotation/json_annotation.dart';

part 'health_status.g.dart';

@JsonSerializable()
class HealthStatus {
  final String status;
  final String version;
  final DateTime timestamp;
  final String database;
  final String cache;

  const HealthStatus({
    required this.status,
    required this.version,
    required this.timestamp,
    required this.database,
    required this.cache,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) =>
      _$HealthStatusFromJson(json);

  Map<String, dynamic> toJson() => _$HealthStatusToJson(this);

  @override
  String toString() {
    return 'HealthStatus{status: $status, version: $version, timestamp: $timestamp, database: $database, cache: $cache}';
  }
}
