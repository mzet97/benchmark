import 'package:vaden/vaden.dart';
import '../models/json_item.dart';

List<Route> jsonRoutes() {
  return [
    Route.get('/json', _jsonHandler),
  ];
}

Future<Response> _jsonHandler(Request request) {
  final items = List<JsonItem>.generate(1000, (i) {
    return JsonItem(
      id: i + 1,
      name: 'Item ${i + 1}',
      value: 'Value ${i + 1}',
      timestamp: DateTime.now(),
    );
  });

  return Response.json(
    body: items.map((item) => item.toJson()).toList(),
  );
}
