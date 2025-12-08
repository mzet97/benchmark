import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final int id;
  final int userId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  @override
  String toString() {
    return 'Order{id: $id, userId: $userId, totalAmount: $totalAmount, status: $status, createdAt: $createdAt}';
  }
}
