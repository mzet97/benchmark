'use strict';

const typeDefs = `#graphql
  type Health {
    status: String!
    version: String!
    timestamp: String!
    database: String!
    cache: String!
  }

  type JsonItem {
    id: Int!
    uuid: String!
    name: String!
    email: String!
    createdAt: String!
    isActive: Boolean!
  }

  type JsonItemsResult {
    items: [JsonItem!]!
    count: Int!
    timestamp: String!
  }

  type User {
    id: Int!
    email: String!
    firstName: String!
    lastName: String!
    age: Int!
    createdAt: String!
  }

  type UserOrderStats {
    userId: Int!
    userName: String!
    totalOrders: Int!
    totalValue: Float!
    averageOrderValue: Float!
  }

  type ComplexOrdersResult {
    periodDays: Int!
    totalUsers: Int!
    data: [UserOrderStats!]!
  }

  type CacheEntry {
    key: String!
    value: String!
    cached: Boolean!
    ttl: Int!
  }

  type Query {
    health: Health!
    jsonItems(limit: Int = 1000): JsonItemsResult!
    user(id: Int!): User
    complexOrders(days: Int = 30): ComplexOrdersResult!
    cache(key: String!): CacheEntry!
  }
`;

module.exports = { typeDefs };
