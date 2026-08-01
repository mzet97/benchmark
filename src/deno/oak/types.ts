// Type definitions for the API

// Mirrors UserResponse in contracts/grpc/benchmark.proto. Wire names are
// camelCase. See contracts/rest/canonical-payloads.md.
export interface User {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  age: number | null;
  createdAt: string;
}

export interface Order {
  id: number;
  user_id: number;
  total_amount: number;
  status: string;
  created_at: string;
}

export interface OrderItem {
  id: number;
  order_id: number;
  product_name: string;
  quantity: number;
  price: number;
  created_at: string;
}

// Mirrors ComplexOrdersResponse and UserOrderStats in the proto.
export interface UserOrderStats {
  userId: number;
  userName: string;
  totalOrders: number;
  totalValue: number;
  averageOrderValue: number;
}

export interface ComplexOrderResult {
  periodDays: number;
  totalUsers: number;
  data: UserOrderStats[];
}

// JsonItem is defined by the payload contract; see ./canonical.ts. The
// interface declared here carried {id, name, value, timestamp}, a shape the
// endpoint no longer returns.
export type { JsonItem } from "./canonical.ts";

export interface HealthStatus {
  status: string;
  version: string;
  timestamp: string;
  database: string;
  cache: string;
}

export interface CacheResponse {
  key: string;
  value: string;
  cached: boolean;
  ttl: number;
}

export interface ErrorResponse {
  error: string;
  message: string;
}

export interface DatabaseConfig {
  connectionString: string;
  minPool: number;
  maxPool: number;
  timeout: number;
}

export interface CacheConfig {
  host: string;
  port: number;
  password?: string;
  ttl: number;
}
