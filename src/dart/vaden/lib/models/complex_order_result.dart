import 'package:json_annotation/json_annotation.dart';

part 'complex_order_result.g.dart';

@JsonSerializable()
class ComplexOrderResult {
  final int periodDays;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final List<OrderSummary> orders;

  const ComplexOrderResult({
    required this.periodDays,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.orders,
  });

  factory ComplexOrderResult.fromJson(Map<String, dynamic> json) =>
      _$ComplexOrderResultFromJson(json);

  Map<String, dynamic> toJson() => _$ComplexOrderResultToJson(this);
}

@JsonSerializable()
class OrderSummary {
  final int orderId;
  final int userId;
  final String userEmail;
  final double totalAmount;
  final int itemsCount;
  final DateTime createdAt;

  const OrderSummary({
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.totalAmount,
    required this.itemsCount,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) =>
      _$OrderSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSummaryToJson(this);
}
