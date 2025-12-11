import 'package:vaden/vaden.dart';
import '../models/complex_order_result.dart';
import '../services/database_service.dart';

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

  if (days <= 0 || days > 365) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Bad Request',
        'message': 'days must be between 1 and 365',
      },
    );
  }

  final users = await databaseService.getComplexUsers(days);

  final result = ComplexQueryResult(
    periodDays: days,
    totalUsers: users.length,
    data: users.map((userData) {
      return UserStats(
        userId: userData['user_id'] as int,
        userName: userData['user_name'] as String,
        totalOrders: userData['total_orders'] as int,
        totalValue: userData['total_value'] as double,
        averageValue: userData['average_value'] as double,
      );
    }).toList(),
  );

  return Response.json(
    body: result.toJson(),
  );
}
