// Type definitions for the API

export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  created_at: string;
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

export interface ComplexOrderResult {
  period_days: number;
  total_orders: number;
  total_revenue: number;
  average_order_value: number;
  orders: Array<{
    order_id: number;
    user_id: number;
    user_email: string;
    total_amount: number;
    items_count: number;
    created_at: string;
  }>;
}

export interface JsonItem {
  id: number;
  name: string;
  value: string;
  timestamp: string;
}

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
