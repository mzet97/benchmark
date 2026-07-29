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

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'cached': cached,
      'ttl': ttl,
    };
  }
}
