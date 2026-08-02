import 'package:graphql/schema.dart';
import 'package:graphql/executor.dart';
import 'package:graphql_angel3_benchmark/canonical.dart';

import 'db.dart';
import 'cache.dart';

GraphQLSchema buildSchema(DatabaseService db, CacheService cache) {
  return GraphQLSchema(
    queryType: GraphQLObjectType(
      'Query',
      [
        GraphQLField(
          'health',
          type: GraphQLNonNull(GraphQLObjectType('Health', [
            GraphQLField('status', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('version', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('timestamp', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('database', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('cache', type: GraphQLNonNull(GraphQLString)),
          ])),
          resolve: (obj, args, ctx) async {
            var dbStatus = 'ok';
            var cacheStatus = 'ok';
            try {
              await db.ping();
            } catch (_) {
              dbStatus = 'error';
            }
            try {
              await cache.ping();
            } catch (_) {
              cacheStatus = 'error';
            }
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
          type: GraphQLNonNull(GraphQLObjectType('JsonItemsResult', [
            GraphQLField('items', type: GraphQLNonNull(GraphQLList(GraphQLNonNull(GraphQLObjectType('JsonItem', [
              GraphQLField('id', type: GraphQLNonNull(GraphQLInt)),
              GraphQLField('uuid', type: GraphQLNonNull(GraphQLString)),
              GraphQLField('name', type: GraphQLNonNull(GraphQLString)),
              GraphQLField('email', type: GraphQLNonNull(GraphQLString)),
              GraphQLField('createdAt', type: GraphQLNonNull(GraphQLString)),
              GraphQLField('isActive', type: GraphQLNonNull(GraphQLBoolean)),
            ])))),
            GraphQLField('count', type: GraphQLNonNull(GraphQLInt)),
            GraphQLField('timestamp', type: GraphQLNonNull(GraphQLString)),
          ])),
          args: [
            GraphQLFieldArg('limit', GraphQLInt, defaultValue: 1000),
          ],
          resolve: (obj, args, ctx) {
            final count = itemCount(args['limit'] as int?);
            final now = DateTime.now().toUtc().toIso8601String();
            final items = List.generate(count, (i) => {
              'id': i,
              'uuid': canonicalUuid(i),
              'name': canonicalName(i),
              'email': canonicalEmail(i),
              'createdAt': canonicalCreatedAt,
              'isActive': canonicalIsActive(i),
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
          type: GraphQLObjectType('User', [
            GraphQLField('id', type: GraphQLNonNull(GraphQLInt)),
            GraphQLField('email', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('firstName', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('lastName', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('age', type: GraphQLNonNull(GraphQLInt)),
            GraphQLField('createdAt', type: GraphQLNonNull(GraphQLString)),
          ]),
          args: [
            GraphQLFieldArg('id', GraphQLNonNull(GraphQLInt)),
          ],
          resolve: (obj, args, ctx) async {
            return await db.getUser(args['id'] as int);
          },
        ),
        GraphQLField(
          'complexOrders',
          type: GraphQLNonNull(GraphQLObjectType('ComplexOrdersResult', [
            GraphQLField('periodDays', type: GraphQLNonNull(GraphQLInt)),
            GraphQLField('totalUsers', type: GraphQLNonNull(GraphQLInt)),
            GraphQLField('data', type: GraphQLNonNull(GraphQLList(GraphQLNonNull(GraphQLObjectType('UserOrderStats', [
              GraphQLField('userId', type: GraphQLNonNull(GraphQLInt)),
              GraphQLField('userName', type: GraphQLNonNull(GraphQLString)),
              GraphQLField('totalOrders', type: GraphQLNonNull(GraphQLInt)),
              GraphQLField('totalValue', type: GraphQLNonNull(GraphQLFloat)),
              GraphQLField('averageOrderValue', type: GraphQLNonNull(GraphQLFloat)),
            ]))))),
          ])),
          args: [
            GraphQLFieldArg('days', GraphQLInt, defaultValue: 30),
          ],
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
          type: GraphQLNonNull(GraphQLObjectType('CacheEntry', [
            GraphQLField('key', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('value', type: GraphQLNonNull(GraphQLString)),
            GraphQLField('cached', type: GraphQLNonNull(GraphQLBoolean)),
            GraphQLField('ttl', type: GraphQLNonNull(GraphQLInt)),
          ])),
          args: [
            GraphQLFieldArg('key', GraphQLNonNull(GraphQLString)),
          ],
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
      ],
    ),
  );
}
