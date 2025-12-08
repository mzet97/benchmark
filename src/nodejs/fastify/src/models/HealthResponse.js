import { z } from 'zod';

// HealthResponse model schema
export const HealthResponseSchema = z.object({
  status: z.string(),
  database: z.string(),
  cache: z.string(),
  timestamp: z.string()
});

// Create health response
export function createHealthResponse(dbHealthy, cacheHealthy) {
  return {
    status: dbHealthy && cacheHealthy ? 'healthy' : 'unhealthy',
    database: dbHealthy ? 'connected' : 'disconnected',
    cache: cacheHealthy ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString()
  };
}

// Validation function
export function validateHealthResponse(data) {
  return HealthResponseSchema.parse(data);
}
