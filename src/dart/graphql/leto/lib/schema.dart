import 'package:leto/leto.dart';

import 'db.dart';
import 'cache.dart';

GraphQLSchema buildSchema(DatabaseService db, CacheService cache) {
  final healthType = GraphQLObjectType('Health', fields: [
    GraphQLField('status', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('version', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('timestamp', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('database', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('cache', type: GraphQLNonNull(GraphQLString)),
  ]);

  final jsonItemType = GraphQLObjectType('JsonItem', fields: [
    GraphQLField('id', type: GraphQLNonNull(GraphQLInt)),
    GraphQLField('uuid', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('name', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('email', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('createdAt', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('isActive', type: GraphQLNonNull(GraphQLBoolean)),
  ]);

  final jsonItemsResultType = GraphQLObjectType('JsonItemsResult', fields: [
    GraphQLField('items', type: GraphQLNonNull(GraphQLList(GraphQLNonNull(jsonItemType)))),
    GraphQLField('count', type: GraphQLNonNull(GraphQLInt)),
    GraphQLField('timestamp', type: GraphQLNonNull(GraphQLString)),
  ]);

  final userType = GraphQLObjectType('User', fields: [
    GraphQLField('id', type: GraphQLNonNull(GraphQLInt)),
    GraphQLField('email', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('firstName', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('lastName', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('age', type: GraphQLNonNull(GraphQLInt)),
    GraphQLField('createdAt', type: GraphQLNonNull(GraphQLString)),
  ]);

  final userOrderStatsType = GraphQLObjectType('UserOrderStats', fields: [
    GraphQLField('userId', type: GraphQLNonNull(GraphQLInt)),
    GraphQLField('userName', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('totalOrders', type: GraphQLNonNull(GraphQLInt)),
    GraphQLField('totalValue', type: GraphQLNonNull(GraphQLFloat)),
    GraphQLField('averageOrderValue', type: GraphQLNonNull(GraphQLFloat)),
  ]);

  final complexOrdersResultType = GraphQLObjectType('ComplexOrdersResult', fields: [
    GraphQLField('periodDays', type: GraphQLNonNull(GraphQLInt)),
    GraphQLField('totalUsers', type: GraphQLNonNull(GraphQLInt)),
    GraphQLField('data', type: GraphQLNonNull(GraphQLList(GraphQLNonNull(userOrderStatsType)))),
  ]);

  final cacheEntryType = GraphQLObjectType('CacheEntry', fields: [
    GraphQLField('key', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('value', type: GraphQLNonNull(GraphQLString)),
    GraphQLField('cached', type: GraphQLNonNull(GraphQLBoolean)),
    GraphQLField('ttl', type: GraphQLNonNull(GraphQLInt)),
  ]);

  final queryType = GraphQLObjectType('Query', fields: [
    GraphQLField(
      'health',
      type: GraphQLNonNull(healthType),
      resolve: (obj, args, ctx) async {
        var dbStatus = 'ok';
        var cacheStatus = 'ok';
        try { await db.ping(); } catch (_) { dbStatus = 'error'; }
        try { await cache.ping(); } catch (_) { cacheStatus = 'error'; }
        return {
          'status': 'ok',
          'version': '1.0.0',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'database': dbStatus,
          'cache': cacheStatus,
        };
      },
    ),
    GraphQLField(
      'jsonItems',
      type: GraphQLNonNull(jsonItemsResultType),
      args: [GraphQLFieldArg('limit', GraphQLInt, defaultValue: 1000)],
      resolve: (obj, args, ctx) {
        final limit = args['limit'] as int? ?? 1000;
        final now = DateTime.now().toUtc().toIso8601String();
        final items = List.generate(limit, (i) => {
          'id': i + 1,
          'uuid': 'item-${i + 1}-uuid',
          'name': 'Item ${i + 1}',
          'email': 'user${i + 1}@example.com',
          'createdAt': now,
          'isActive': i % 3 != 0,
        });
        return {
          'items': items,
          'count': items.length,
          'timestamp': now,
        };
      },
    ),
    GraphQLField(
      'user',
      type: userType,
      args: [GraphQLFieldArg('id', GraphQLNonNull(GraphQLInt))],
      resolve: (obj, args, ctx) async {
        return await db.getUser(args['id'] as int);
      },
    ),
    GraphQLField(
      'complexOrders',
      type: GraphQLNonNull(complexOrdersResultType),
      args: [GraphQLFieldArg('days', GraphQLInt, defaultValue: 30)],
      resolve: (obj, args, ctx) async {
        final days = args['days'] as int? ?? 30;
        final data = await db.getComplexOrders(days);
        return {
          'periodDays': days,
          'totalUsers': data.length,
          'data': data,
        };
      },
    ),
    GraphQLField(
      'cache',
      type: GraphQLNonNull(cacheEntryType),
      args: [GraphQLFieldArg('key', GraphQLNonNull(GraphQLString))],
      resolve: (obj, args, ctx) async {
        final key = args['key'] as String;
        final value = await cache.get(key);
        if (value != null) {
          final ttlVal = await cache.ttl(key);
          return {
            'key': key,
            'value': value.toString(),
            'cached': true,
            'ttl': ttlVal >= 0 ? ttlVal : 0,
          };
        }
        final generated = '{"key": "$key", "generated": true}';
        await cache.set(key, generated, 300);
        return {
          'key': key,
          'value': generated,
          'cached': false,
          'ttl': 300,
        };
      },
    ),
  ]);

  return GraphQLSchema(queryType: queryType);
}
