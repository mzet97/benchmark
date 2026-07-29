import 'package:graphql_server2/graphql_server2.dart';
import 'resolvers.dart';

GraphQLSchema buildSchema() {
  final healthType = GraphQLObjectType('Health', {
    'status': GraphQLField(GraphQLNonNull(GraphQLString)),
    'version': GraphQLField(GraphQLNonNull(GraphQLString)),
    'timestamp': GraphQLField(GraphQLNonNull(GraphQLString)),
    'database': GraphQLField(GraphQLNonNull(GraphQLString)),
    'cache': GraphQLField(GraphQLNonNull(GraphQLString)),
  });

  final jsonItemType = GraphQLObjectType('JsonItem', {
    'id': GraphQLField(GraphQLNonNull(GraphQLInt)),
    'uuid': GraphQLField(GraphQLNonNull(GraphQLString)),
    'name': GraphQLField(GraphQLNonNull(GraphQLString)),
    'email': GraphQLField(GraphQLNonNull(GraphQLString)),
    'createdAt': GraphQLField(GraphQLNonNull(GraphQLString)),
    'isActive': GraphQLField(GraphQLNonNull(GraphQLBoolean)),
  });

  final jsonItemsResultType = GraphQLObjectType('JsonItemsResult', {
    'items': GraphQLField(GraphQLNonNull(GraphQLList(GraphQLNonNull(jsonItemType)))),
    'count': GraphQLField(GraphQLNonNull(GraphQLInt)),
    'timestamp': GraphQLField(GraphQLNonNull(GraphQLString)),
  });

  final userType = GraphQLObjectType('User', {
    'id': GraphQLField(GraphQLNonNull(GraphQLInt)),
    'email': GraphQLField(GraphQLNonNull(GraphQLString)),
    'firstName': GraphQLField(GraphQLNonNull(GraphQLString)),
    'lastName': GraphQLField(GraphQLNonNull(GraphQLString)),
    'age': GraphQLField(GraphQLNonNull(GraphQLInt)),
    'createdAt': GraphQLField(GraphQLNonNull(GraphQLString)),
  });

  final userOrderStatsType = GraphQLObjectType('UserOrderStats', {
    'userId': GraphQLField(GraphQLNonNull(GraphQLInt)),
    'userName': GraphQLField(GraphQLNonNull(GraphQLString)),
    'totalOrders': GraphQLField(GraphQLNonNull(GraphQLInt)),
    'totalValue': GraphQLField(GraphQLNonNull(GraphQLFloat)),
    'averageOrderValue': GraphQLField(GraphQLNonNull(GraphQLFloat)),
  });

  final complexOrdersResultType = GraphQLObjectType('ComplexOrdersResult', {
    'periodDays': GraphQLField(GraphQLNonNull(GraphQLInt)),
    'totalUsers': GraphQLField(GraphQLNonNull(GraphQLInt)),
    'data': GraphQLField(GraphQLNonNull(GraphQLList(GraphQLNonNull(userOrderStatsType)))),
  });

  final cacheEntryType = GraphQLObjectType('CacheEntry', {
    'key': GraphQLField(GraphQLNonNull(GraphQLString)),
    'value': GraphQLField(GraphQLNonNull(GraphQLString)),
    'cached': GraphQLField(GraphQLNonNull(GraphQLBoolean)),
    'ttl': GraphQLField(GraphQLNonNull(GraphQLInt)),
  });

  final queryType = GraphQLObjectType('Query', {
    'health': GraphQLField(
      GraphQLNonNull(healthType),
      resolve: (_, __, context) => (context as GraphQLContext).resolvers.resolveHealth(),
    ),
    'jsonItems': GraphQLField(
      GraphQLNonNull(jsonItemsResultType),
      args: {
        'limit': GraphQLArgument(GraphQLInt, defaultValue: 1000),
      },
      resolve: (obj, args, context) =>
          (context as GraphQLContext).resolvers.resolveJsonItems(args['limit'] as int? ?? 1000),
    ),
    'user': GraphQLField(
      userType,
      args: {
        'id': GraphQLArgument(GraphQLNonNull(GraphQLInt)),
      },
      resolve: (obj, args, context) =>
          (context as GraphQLContext).resolvers.resolveUser(args['id'] as int),
    ),
    'complexOrders': GraphQLField(
      GraphQLNonNull(complexOrdersResultType),
      args: {
        'days': GraphQLArgument(GraphQLInt, defaultValue: 30),
      },
      resolve: (obj, args, context) =>
          (context as GraphQLContext).resolvers.resolveComplexOrders(args['days'] as int? ?? 30),
    ),
    'cache': GraphQLField(
      GraphQLNonNull(cacheEntryType),
      args: {
        'key': GraphQLArgument(GraphQLNonNull(GraphQLString)),
      },
      resolve: (obj, args, context) =>
          (context as GraphQLContext).resolvers.resolveCache(args['key'] as String),
    ),
  });

  return GraphQLSchema(query: queryType);
}

class GraphQLContext {
  final Resolvers resolvers;
  GraphQLContext(this.resolvers);
}
