// Middleware is implemented in bin/server.dart
// using Shelf middleware pattern directly.
//
// Middleware applied:
// - CORS: Adds Access-Control-Allow-Origin: *
// - Logging: Logs method, path, status, duration
// - Error: Catches unhandled exceptions, returns 500
