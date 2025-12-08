import 'package:json_annotation/json_annotation.dart';

part 'cache_response.g.dart';

@JsonSerializable()
class CacheResponse {
  final String key;
  final String value;
  final bool cached;
  final int ttl;

  const CacheResponse({
    required this.key,
    required this.value,
    required this.cached,
    required this.ttl,
  });

  factory CacheResponse.fromJson(Map<String, dynamic> json) =>
      _$CacheResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CacheResponseToJson(this);

  @override
  String toString() {
    return 'CacheResponse{key: $key, value: $value, cached: $cached, ttl: $ttl}';
  }
}
