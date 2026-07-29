// Generated ConnectRPC service definition for benchmark.proto
// Using @connectrpc/connect MethodKind

const { MethodKind } = require('@connectrpc/connect');
const {
  HealthRequest,
  HealthResponse,
  JsonItemsRequest,
  JsonItemsResponse,
  GetUserRequest,
  UserResponse,
  ComplexOrdersRequest,
  ComplexOrdersResponse,
  CacheRequest,
  CacheResponse,
} = require('./benchmark_pb');

/**
 * BenchmarkService service definition for ConnectRPC.
 * This defines the RPC methods, their request/response types, and method kinds.
 */
const BenchmarkService = {
  typeName: 'benchmark.BenchmarkService',
  methods: {
    /**
     * Scenario 1: Health check
     */
    health: {
      name: 'Health',
      I: HealthRequest,
      O: HealthResponse,
      kind: MethodKind.Unary,
    },
    /**
     * Scenario 2: JSON serialization (1000 objects)
     */
    getJsonItems: {
      name: 'GetJsonItems',
      I: JsonItemsRequest,
      O: JsonItemsResponse,
      kind: MethodKind.Unary,
    },
    /**
     * Scenario 3: Simple database query (single row)
     */
    getUser: {
      name: 'GetUser',
      I: GetUserRequest,
      O: UserResponse,
      kind: MethodKind.Unary,
    },
    /**
     * Scenario 4: Complex database query (JOIN + aggregation)
     */
    getComplexOrders: {
      name: 'GetComplexOrders',
      I: ComplexOrdersRequest,
      O: ComplexOrdersResponse,
      kind: MethodKind.Unary,
    },
    /**
     * Scenario 5: Cache hit/miss
     */
    getCacheValue: {
      name: 'GetCacheValue',
      I: CacheRequest,
      O: CacheResponse,
      kind: MethodKind.Unary,
    },
  },
};

module.exports = { BenchmarkService };
