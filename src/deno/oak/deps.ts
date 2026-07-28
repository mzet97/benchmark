// External dependencies (imported from CDN)
// This file centralizes all external imports

// Oak framework
export {
  Application,
  Router,
  Context,
  Middleware,
  Status,
} from "oak";

// PostgreSQL driver
export { Client } from "postgres";

// Redis client
export { Redis } from "redis";

// Validation
export { z } from "zod";

// Environment variables
export { config as dotenvConfig } from "dotenv";

// Logging
export { Console } from "console";

// HTTP status - re-exported from oak
export { Status as HttpStatus } from "oak";
