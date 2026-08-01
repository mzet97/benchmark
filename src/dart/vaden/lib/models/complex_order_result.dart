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
      'periodDays': periodDays,
      'totalUsers': totalUsers,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class UserStats {
  final int userId;
  final String userName;
  final int totalOrders;
  final double totalValue;
  final double averageOrderValue;

  const UserStats({
    required this.userId,
    required this.userName,
    required this.totalOrders,
    required this.totalValue,
    required this.averageOrderValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'totalOrders': totalOrders,
      'totalValue': totalValue,
      'averageOrderValue': averageOrderValue,
    };
  }
}
