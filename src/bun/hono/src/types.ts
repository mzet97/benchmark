export interface HealthStatus {
  status: string;
  version: string;
  timestamp: string;
  database: string;
  cache: string;
}

export interface JsonItem {
  id: number;
  name: string;
  value: string;
  timestamp: string;
}

export interface User {
  id: number;
  name: string;
}

export interface CacheResponse {
  key: string;
  value: string;
  cached: boolean;
  ttl: number;
}

export interface DatabaseConfig {
  url: string;
  min: number;
  max: number;
}

export interface CacheConfig {
  url: string;
  ttl: number;
}

export interface AppConfig {
  port: number;
  host: string;
  logLevel: string;
  debug: boolean;
}
