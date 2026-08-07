// Builds the GraphQL schema using the leto_schema API.
//
// leto_schema exposes field/object construction via the `field()` and
// `objectType()` factories (in gen.dart), which infer generics and accept a
// bare resolver function. The GraphQLObjectField constructor, by contrast,
// expects a FieldResolver wrapper, so the factories are the idiomatic entry
// point. API mappings from the classic graphql builder that this file used
// before:
//   GraphQLField(name, type:, args:, resolve:) -> field(name, type, inputs:, resolve:)
//   GraphQLFieldArg  -> GraphQLFieldInput
//   GraphQLNonNull(t)-> t.nonNull()
//   GraphQLList(t)   -> listOf(t)
//   GraphQLString/Int/Float/Boolean -> graphQLString/graphQLInt/...
//
// leto invokes a resolver as (parent, ctx): two parameters, with arguments
// reached via ctx.args rather than a third positional parameter.
import 'package:graphql_leto_benchmark/canonical.dart';
import 'package:leto_schema/leto_schema.dart';

import 'db.dart';
import 'cache.dart';

/// Leaf scalar field: resolves to parent[fieldName].
GraphQLObjectField<Object?, Object?, Object?> _leaf(
        String name, GraphQLType type) =>
    field(name, type, resolve: (obj, _) => (obj is Map) ? obj[name] : null);

GraphQLSchema buildSchema(DatabaseService db, CacheService cache) {
  final healthType = objectType('Health', fields: [
    _leaf('status', graphQLString.nonNull()),
    _leaf('version', graphQLString.nonNull()),
    _leaf('timestamp', graphQLString.nonNull()),
    _leaf('database', graphQLString.nonNull()),
    _leaf('cache', graphQLString.nonNull()),
  ]);

  final jsonItemType = objectType('JsonItem', fields: [
    _leaf('id', graphQLInt.nonNull()),
    _leaf('uuid', graphQLString.nonNull()),
    _leaf('name', graphQLString.nonNull()),
    _leaf('email', graphQLString.nonNull()),
    _leaf('createdAt', graphQLString.nonNull()),
    _leaf('isActive', graphQLBoolean.nonNull()),
  ]);

  final jsonItemsResultType = objectType('JsonItemsResult', fields: [
    _leaf('items', listOf(jsonItemType.nonNull())),
    _leaf('count', graphQLInt.nonNull()),
    _leaf('timestamp', graphQLString.nonNull()),
  ]);

  final userType = objectType('User', fields: [
    _leaf('id', graphQLInt.nonNull()),
    _leaf('email', graphQLString.nonNull()),
    _leaf('firstName', graphQLString.nonNull()),
    _leaf('lastName', graphQLString.nonNull()),
    _leaf('age', graphQLInt.nonNull()),
    _leaf('createdAt', graphQLString.nonNull()),
  ]);

  final userOrderStatsType = objectType('UserOrderStats', fields: [
    _leaf('userId', graphQLInt.nonNull()),
    _leaf('userName', graphQLString.nonNull()),
    _leaf('totalOrders', graphQLInt.nonNull()),
    _leaf('totalValue', graphQLFloat.nonNull()),
    _leaf('averageOrderValue', graphQLFloat.nonNull()),
  ]);

  final complexOrdersResultType = objectType('ComplexOrdersResult', fields: [
    _leaf('periodDays', graphQLInt.nonNull()),
    _leaf('totalUsers', graphQLInt.nonNull()),
    _leaf('data', listOf(userOrderStatsType.nonNull())),
  ]);

  final cacheEntryType = objectType('CacheEntry', fields: [
    _leaf('key', graphQLString.nonNull()),
    _leaf('value', graphQLString.nonNull()),
    _leaf('cached', graphQLBoolean.nonNull()),
    _leaf('ttl', graphQLInt.nonNull()),
  ]);

  final queryType = objectType('Query', fields: [
    field(
      'health',
      healthType.nonNull(),
      resolve: (obj, ctx) async {
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
    field(
      'jsonItems',
      jsonItemsResultType.nonNull(),
      inputs: [GraphQLFieldInput('limit', graphQLInt, defaultValue: 1000)],
      resolve: (obj, ctx) {
        final count = itemCount(ctx.args['limit'] as int?);
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
    field(
      'user',
      userType,
      inputs: [GraphQLFieldInput('id', graphQLInt.nonNull())],
      resolve: (obj, ctx) async {
        return await db.getUser(ctx.args['id'] as int);
      },
    ),
    field(
      'complexOrders',
      complexOrdersResultType.nonNull(),
      inputs: [GraphQLFieldInput('days', graphQLInt, defaultValue: 30)],
      resolve: (obj, ctx) async {
        final days = ctx.args['days'] as int? ?? 30;
        final data = await db.getComplexOrders(days);
        return {
          'periodDays': days,
          'totalUsers': data.length,
          'data': data,
        };
      },
    ),
    field(
      'cache',
      cacheEntryType.nonNull(),
      inputs: [GraphQLFieldInput('key', graphQLString.nonNull())],
      resolve: (obj, ctx) async {
        final key = ctx.args['key'] as String;
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
