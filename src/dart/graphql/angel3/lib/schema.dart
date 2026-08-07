// Builds the GraphQL schema using the graphql_schema2 API (the *2 fork that
// angel3_graphql depends on). The previous code imported
// `package:graphql/schema.dart`, but the resolved `graphql` package is a
// client-only distribution with no schema/executor exports; the schema types
// live in `graphql_schema2`, re-exported transitively by `angel3_graphql`.
//
// graphql_schema2 renames the classic graphql builder API:
//   GraphQLField      -> GraphQLObjectField  (positional type, not `type:`)
//   GraphQLFieldArg   -> GraphQLFieldInput   (passed via `arguments:`)
//   GraphQLNonNull(t) -> t.nonNullable()
//   GraphQLList(t)    -> listOf(t)
//   GraphQLString/Int/Float/Boolean -> graphQLString/graphQLInt/...
//   GraphQLObjectType -> objectType(name, fields: [...]) factory
// The resolver arity drops from (obj, args, ctx) to (obj, args). A resolver
// is required on every field; for leaf scalars we read the value by field
// name from the parent map.
import 'package:graphql_angel3_benchmark/canonical.dart';
import 'package:graphql_schema2/graphql_schema2.dart';

import 'db.dart';
import 'cache.dart';

/// Leaf scalar field: resolves to parent[fieldName].
GraphQLObjectField _leaf(String name, GraphQLType type) =>
    GraphQLObjectField(name, type,
        resolve: (obj, _) => (obj is Map) ? obj[name] : null);

GraphQLSchema buildSchema(DatabaseService db, CacheService cache) {
  return GraphQLSchema(
    queryType: objectType(
      'Query',
      fields: [
        GraphQLObjectField(
          'health',
          objectType('Health', fields: [
            _leaf('status', graphQLString.nonNullable()),
            _leaf('version', graphQLString.nonNullable()),
            _leaf('timestamp', graphQLString.nonNullable()),
            _leaf('database', graphQLString.nonNullable()),
            _leaf('cache', graphQLString.nonNullable()),
          ]).nonNullable(),
          resolve: (obj, args) async {
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
        GraphQLObjectField(
          'jsonItems',
          objectType('JsonItemsResult', fields: [
            _leaf('items',
                listOf(graphQLNonNullable(objectType('JsonItem', fields: [
              _leaf('id', graphQLInt.nonNullable()),
              _leaf('uuid', graphQLString.nonNullable()),
              _leaf('name', graphQLString.nonNullable()),
              _leaf('email', graphQLString.nonNullable()),
              _leaf('createdAt', graphQLString.nonNullable()),
              _leaf('isActive', graphQLBoolean.nonNullable()),
            ])))),
            _leaf('count', graphQLInt.nonNullable()),
            _leaf('timestamp', graphQLString.nonNullable()),
          ]).nonNullable(),
          arguments: [
            GraphQLFieldInput('limit', graphQLInt, defaultValue: 1000),
          ],
          resolve: (obj, args) {
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
        GraphQLObjectField(
          'user',
          objectType('User', fields: [
            _leaf('id', graphQLInt.nonNullable()),
            _leaf('email', graphQLString.nonNullable()),
            _leaf('firstName', graphQLString.nonNullable()),
            _leaf('lastName', graphQLString.nonNullable()),
            _leaf('age', graphQLInt.nonNullable()),
            _leaf('createdAt', graphQLString.nonNullable()),
          ]),
          arguments: [
            GraphQLFieldInput('id', graphQLInt.nonNullable()),
          ],
          resolve: (obj, args) async {
            return await db.getUser(args['id'] as int);
          },
        ),
        GraphQLObjectField(
          'complexOrders',
          objectType('ComplexOrdersResult', fields: [
            _leaf('periodDays', graphQLInt.nonNullable()),
            _leaf('totalUsers', graphQLInt.nonNullable()),
            _leaf(
              'data',
              listOf(graphQLNonNullable(objectType('UserOrderStats', fields: [
                _leaf('userId', graphQLInt.nonNullable()),
                _leaf('userName', graphQLString.nonNullable()),
                _leaf('totalOrders', graphQLInt.nonNullable()),
                _leaf('totalValue', graphQLFloat.nonNullable()),
                _leaf('averageOrderValue', graphQLFloat.nonNullable()),
              ]))),
            ),
          ]).nonNullable(),
          arguments: [
            GraphQLFieldInput('days', graphQLInt, defaultValue: 30),
          ],
          resolve: (obj, args) async {
            final days = args['days'] as int? ?? 30;
            final data = await db.getComplexOrders(days);
            return {
              'periodDays': days,
              'totalUsers': data.length,
              'data': data,
            };
          },
        ),
        GraphQLObjectField(
          'cache',
          objectType('CacheEntry', fields: [
            _leaf('key', graphQLString.nonNullable()),
            _leaf('value', graphQLString.nonNullable()),
            _leaf('cached', graphQLBoolean.nonNullable()),
            _leaf('ttl', graphQLInt.nonNullable()),
          ]).nonNullable(),
          arguments: [
            GraphQLFieldInput('key', graphQLString.nonNullable()),
          ],
          resolve: (obj, args) async {
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
