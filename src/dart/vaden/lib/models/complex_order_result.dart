import 'package:json_annotation/json_annotation.dart';

part 'complex_order_result.g.dart';

@JsonSerializable()
class ComplexQueryResult {
  final int periodDays;
  final int totalUsers;
  final List<UserStats> data;

  const ComplexQueryResult({
    required this.periodDays,
    required this.totalUsers,
    required this.data,
  });

  factory ComplexQueryResult.fromJson(Map<String, dynamic> json) =>
      _$ComplexQueryResultFromJson(json);

  Map<String, dynamic> toJson() => _$ComplexQueryResultToJson(this);
}

@JsonSerializable()
class UserStats {
  final int userId;
  final String userName;
  final int totalOrders;
  final double totalValue;
  final double averageValue;

  const UserStats({
    required this.userId,
    required this.userName,
    required this.totalOrders,
    required this.totalValue,
    required this.averageValue,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatsToJson(this);
}
