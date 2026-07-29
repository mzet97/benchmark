// Generated protobuf message types for benchmark.proto
// Using @bufbuild/protobuf v1.x MessageType

const { MessageType } = require('@bufbuild/protobuf');

/**
 * HealthRequest message type
 */
const HealthRequest = new MessageType('benchmark.HealthRequest', []);

/**
 * HealthResponse message type
 */
const HealthResponse = new MessageType('benchmark.HealthResponse', [
  { no: 1, name: 'status', kind: 'scalar', T: 9 /* STRING */ },
  { no: 2, name: 'version', kind: 'scalar', T: 9 /* STRING */ },
  { no: 3, name: 'timestamp', kind: 'scalar', T: 9 /* STRING */ },
  { no: 4, name: 'database', kind: 'scalar', T: 9 /* STRING */ },
  { no: 5, name: 'cache', kind: 'scalar', T: 9 /* STRING */ },
]);

/**
 * JsonItemsRequest message type
 */
const JsonItemsRequest = new MessageType('benchmark.JsonItemsRequest', [
  { no: 1, name: 'limit', kind: 'scalar', T: 5 /* INT32 */ },
]);

/**
 * JsonItem message type
 */
const JsonItem = new MessageType('benchmark.JsonItem', [
  { no: 1, name: 'id', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 2, name: 'uuid', kind: 'scalar', T: 9 /* STRING */ },
  { no: 3, name: 'name', kind: 'scalar', T: 9 /* STRING */ },
  { no: 4, name: 'email', kind: 'scalar', T: 9 /* STRING */ },
  { no: 5, name: 'created_at', kind: 'scalar', T: 9 /* STRING */ },
  { no: 6, name: 'is_active', kind: 'scalar', T: 8 /* BOOL */ },
]);

/**
 * JsonItemsResponse message type
 */
const JsonItemsResponse = new MessageType('benchmark.JsonItemsResponse', [
  { no: 1, name: 'items', kind: 'message', T: JsonItem, repeated: true },
  { no: 2, name: 'count', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 3, name: 'timestamp', kind: 'scalar', T: 9 /* STRING */ },
]);

/**
 * GetUserRequest message type
 */
const GetUserRequest = new MessageType('benchmark.GetUserRequest', [
  { no: 1, name: 'id', kind: 'scalar', T: 5 /* INT32 */ },
]);

/**
 * UserResponse message type
 */
const UserResponse = new MessageType('benchmark.UserResponse', [
  { no: 1, name: 'id', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 2, name: 'email', kind: 'scalar', T: 9 /* STRING */ },
  { no: 3, name: 'first_name', kind: 'scalar', T: 9 /* STRING */ },
  { no: 4, name: 'last_name', kind: 'scalar', T: 9 /* STRING */ },
  { no: 5, name: 'age', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 6, name: 'created_at', kind: 'scalar', T: 9 /* STRING */ },
]);

/**
 * ComplexOrdersRequest message type
 */
const ComplexOrdersRequest = new MessageType('benchmark.ComplexOrdersRequest', [
  { no: 1, name: 'days', kind: 'scalar', T: 5 /* INT32 */ },
]);

/**
 * UserOrderStats message type
 */
const UserOrderStats = new MessageType('benchmark.UserOrderStats', [
  { no: 1, name: 'user_id', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 2, name: 'user_name', kind: 'scalar', T: 9 /* STRING */ },
  { no: 3, name: 'total_orders', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 4, name: 'total_value', kind: 'scalar', T: 1 /* DOUBLE */ },
  { no: 5, name: 'average_order_value', kind: 'scalar', T: 1 /* DOUBLE */ },
]);

/**
 * ComplexOrdersResponse message type
 */
const ComplexOrdersResponse = new MessageType('benchmark.ComplexOrdersResponse', [
  { no: 1, name: 'period_days', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 2, name: 'total_users', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 3, name: 'data', kind: 'message', T: UserOrderStats, repeated: true },
]);

/**
 * CacheRequest message type
 */
const CacheRequest = new MessageType('benchmark.CacheRequest', [
  { no: 1, name: 'key', kind: 'scalar', T: 9 /* STRING */ },
]);

/**
 * CacheResponse message type
 */
const CacheResponse = new MessageType('benchmark.CacheResponse', [
  { no: 1, name: 'key', kind: 'scalar', T: 9 /* STRING */ },
  { no: 2, name: 'value', kind: 'scalar', T: 9 /* STRING */ },
  { no: 3, name: 'cached', kind: 'scalar', T: 8 /* BOOL */ },
  { no: 4, name: 'ttl', kind: 'scalar', T: 5 /* INT32 */ },
  { no: 5, name: 'timestamp', kind: 'scalar', T: 9 /* STRING */ },
]);

module.exports = {
  HealthRequest,
  HealthResponse,
  JsonItemsRequest,
  JsonItem,
  JsonItemsResponse,
  GetUserRequest,
  UserResponse,
  ComplexOrdersRequest,
  UserOrderStats,
  ComplexOrdersResponse,
  CacheRequest,
  CacheResponse,
};
