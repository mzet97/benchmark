class JsonItem {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool isActive;

  const JsonItem({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
