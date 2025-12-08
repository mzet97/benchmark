import 'package:vaden/vaden.dart';
import '../models/complex_order_result.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

List<Route> databaseRoutes() {
  return [
    Route.get('/db/simple', _simpleDbHandler),
    Route.get('/db/complex', _complexDbHandler),
  ];
}

Future<Response> _simpleDbHandler(Request request) async {
  final databaseService = request.context['databaseService'] as DatabaseService;

  final idParam = request.url.queryParameters['id'];
  if (idParam == null) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Bad Request',
        'message': 'id parameter is required',
      },
    );
  }

  final userId = int.tryParse(idParam);
  if (userId == null) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Bad Request',
        'message': 'id must be a number',
      },
    );
  }

  final user = await databaseService.getUser(userId);
  if (user == null) {
    return Response.json(
      statusCode: 404,
      body: {
        'error': 'Not Found',
        'message': 'User not found',
      },
    );
  }

  return Response.json(
    body: user.toJson(),
  );
}

Future<Response> _complexDbHandler(Request request) async {
  final databaseService = request.context['databaseService'] as DatabaseService;

  final daysParam = request.url.queryParameters['days'];
  final days = daysParam != null ? int.tryParse(daysParam) ?? 30 : 30;

  if (days < 0) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Bad Request',
        'message': 'days must be a positive number',
      },
    );
  }

  final orders = await databaseService.getComplexOrders(days);

  final totalOrders = orders.length;
  final totalRevenue = orders.fold<double>(
    0,
    (sum, order) => sum + (order['total_amount'] as double),
  );
  final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

  final result = ComplexOrderResult(
    periodDays: days,
    totalOrders: totalOrders,
    totalRevenue: double.parse(totalRevenue.toStringAsFixed(2)),
    averageOrderValue: double.parse(averageOrderValue.toStringAsFixed(2)),
    orders: orders.map((order) {
      return OrderSummary(
        orderId: order['order_id'] as int,
        userId: order['user_id'] as int,
        userEmail: order['user_email'] as String,
        totalAmount: order['total_amount'] as double,
        itemsCount: order['items_count'] as int,
        createdAt: order['created_at'] as DateTime,
      );
    }).toList(),
  );

  return Response.json(
    body: result.toJson(),
  );
}
