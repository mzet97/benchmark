// Builds the GraphQL schema using the graphql_schema2 API (the schema layer
// that graphql_server2 v3 depends on). The previous code used the classic
// `graphql` builder API (GraphQLField / GraphQLNonNull / GraphQLArgument /
// the GraphQLObjectType constructor), none of which exist in graphql_schema2:
//   GraphQLField       -> GraphQLObjectField (positional name, type)
//   GraphQLArgument    -> GraphQLFieldInput  (passed via `arguments:`)
//   GraphQLNonNull(t)  -> t.nonNullable()
//   GraphQLList(t)     -> listOf(t)
//   GraphQLObjectType  -> objectType(name, fields: [...]) factory
//   GraphQLString/Int/Float/Boolean -> graphQLString/graphQLInt/...
//
// graphql_schema2 resolves a field via resolve(obj, args) -- two parameters,
// no per-request context -- so the resolvers are closed over directly rather
// than read from a context object. A resolver is required on every field; for
// leaf scalars we read the value by field name from the parent map.
import 'package:graphql_schema2/graphql_schema2.dart';
import 'package:graphql_server2/graphql_server2.dart';
import 'package:graphql_server2_benchmark/resolvers.dart';

/// Leaf scalar field: resolves to parent[fieldName].
GraphQLObjectField _leaf(String name, GraphQLType type) =>
    GraphQLObjectField(name, type,
        resolve: (obj, _) => (obj is Map) ? obj[name] : null);

/// Build the executable schema. The [resolvers] are closed over so field
/// resolvers (which only receive (obj, args) in this library) can reach them.
GraphQL buildSchema(Resolvers resolvers) {
  final jsonItemType = objectType('JsonItem', fields: [
    _leaf('id', graphQLInt.nonNullable()),
    _leaf('uuid', graphQLString.nonNullable()),
    _leaf('name', graphQLString.nonNullable()),
    _leaf('email', graphQLString.nonNullable()),
    _leaf('createdAt', graphQLString.nonNullable()),
    _leaf('isActive', graphQLBoolean.nonNullable()),
  ]);

  final jsonItemsResultType = objectType('JsonItemsResult', fields: [
    _leaf('items', listOf(jsonItemType.nonNullable())),
    _leaf('count', graphQLInt.nonNullable()),
    _leaf('timestamp', graphQLString.nonNullable()),
  ]);

  final userType = objectType('User', fields: [
    _leaf('id', graphQLInt.nonNullable()),
    _leaf('email', graphQLString.nonNullable()),
    _leaf('firstName', graphQLString.nonNullable()),
    _leaf('lastName', graphQLString.nonNullable()),
    _leaf('age', graphQLInt.nonNullable()),
    _leaf('createdAt', graphQLString.nonNullable()),
  ]);

  final userOrderStatsType = objectType('UserOrderStats', fields: [
    _leaf('userId', graphQLInt.nonNullable()),
    _leaf('userName', graphQLString.nonNullable()),
    _leaf('totalOrders', graphQLInt.nonNullable()),
    _leaf('totalValue', graphQLFloat.nonNullable()),
    _leaf('averageOrderValue', graphQLFloat.nonNullable()),
  ]);

  final complexOrdersResultType = objectType('ComplexOrdersResult', fields: [
    _leaf('periodDays', graphQLInt.nonNullable()),
    _leaf('totalUsers', graphQLInt.nonNullable()),
    _leaf('data', listOf(userOrderStatsType.nonNullable())),
  ]);

  final cacheEntryType = objectType('CacheEntry', fields: [
    _leaf('key', graphQLString.nonNullable()),
    _leaf('value', graphQLString.nonNullable()),
    _leaf('cached', graphQLBoolean.nonNullable()),
    _leaf('ttl', graphQLInt.nonNullable()),
  ]);

  final healthType = objectType('Health', fields: [
    _leaf('status', graphQLString.nonNullable()),
    _leaf('version', graphQLString.nonNullable()),
    _leaf('timestamp', graphQLString.nonNullable()),
    _leaf('database', graphQLString.nonNullable()),
    _leaf('cache', graphQLString.nonNullable()),
  ]);

  final queryType = objectType('Query', fields: [
    GraphQLObjectField(
      'health',
      healthType.nonNullable(),
      resolve: (_, __) => resolvers.resolveHealth(),
    ),
    GraphQLObjectField(
      'jsonItems',
      jsonItemsResultType.nonNullable(),
      arguments: [
        GraphQLFieldInput('limit', graphQLInt, defaultValue: 1000),
      ],
      resolve: (_, args) =>
          resolvers.resolveJsonItems(args['limit'] as int? ?? 1000),
    ),
    GraphQLObjectField(
      'user',
      userType,
      arguments: [
        GraphQLFieldInput('id', graphQLInt.nonNullable()),
      ],
      resolve: (_, args) => resolvers.resolveUser(args['id'] as int),
    ),
    GraphQLObjectField(
      'complexOrders',
      complexOrdersResultType.nonNullable(),
      arguments: [
        GraphQLFieldInput('days', graphQLInt, defaultValue: 30),
      ],
      resolve: (_, args) =>
          resolvers.resolveComplexOrders(args['days'] as int? ?? 30),
    ),
    GraphQLObjectField(
      'cache',
      cacheEntryType.nonNullable(),
      arguments: [
        GraphQLFieldInput('key', graphQLString.nonNullable()),
      ],
      resolve: (_, args) => resolvers.resolveCache(args['key'] as String),
    ),
  ]);

  return GraphQL(graphQLSchema(queryType: queryType));
}
