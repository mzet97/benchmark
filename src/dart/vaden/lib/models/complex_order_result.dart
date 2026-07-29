class ComplexQueryResult {
  final int periodDays;
  final int totalUsers;
  final List<UserStats> data;

  const ComplexQueryResult({
    required this.periodDays,
    required this.totalUsers,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'period_days': periodDays,
      'total_users': totalUsers,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'total_orders': totalOrders,
      'total_value': totalValue,
      'average_value': averageValue,
    };
  }
}
