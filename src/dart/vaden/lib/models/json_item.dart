import 'package:json_annotation/json_annotation.dart';

part 'json_item.g.dart';

@JsonSerializable()
class JsonItem {
  final int id;
  final String name;
  final String value;
  final DateTime timestamp;

  const JsonItem({
    required this.id,
    required this.name,
    required this.value,
    required this.timestamp,
  });

  factory JsonItem.fromJson(Map<String, dynamic> json) =>
      _$JsonItemFromJson(json);

  Map<String, dynamic> toJson() => _$JsonItemToJson(this);

  @override
  String toString() {
    return 'JsonItem{id: $id, name: $name, value: $value, timestamp: $timestamp}';
  }
}
