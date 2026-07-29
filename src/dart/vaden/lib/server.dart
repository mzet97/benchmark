// This file is kept for reference.
// The actual server entrypoint is bin/server.dart
// which uses Shelf + shelf_router (the foundation of Vaden framework).
//
// Vaden (https://doc.vaden.dev) is built on top of Shelf.
// For benchmark purposes, we use Shelf directly to avoid
// build_runner code generation complexity.
//
// Framework: Vaden (Shelf-based)
// Runtime: Dart AOT compiled
// Database: PostgreSQL via postgres package
// Cache: Redis via redis package
