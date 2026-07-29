package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"graphql-gqlgen/cache"
	"graphql-gqlgen/db"
	"graphql-gqlgen/graph"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/transport"
)

func main() {
	ctx := context.Background()

	// Connect to PostgreSQL
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://benchmark:benchmark@localhost:5432/benchmark"
	}
	database, err := db.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close()

	// Ensure schema exists
	if err := database.EnsureSchema(ctx); err != nil {
		log.Fatalf("Failed to ensure schema: %v", err)
	}

	// Connect to Redis
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "redis://localhost:6379"
	}
	cacheClient, err := cache.New(ctx, redisURL)
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	defer cacheClient.Close()

	// Create resolver
	resolver := &graph.Resolver{
		DB:    database,
		Cache: cacheClient,
	}

	// Create GraphQL server - POST only, no playground
	srv := handler.NewDefaultServer(graph.NewExecutableSchema(graph.Config{
		Resolvers: resolver,
	}))

	// Restrict to POST transport only
	srv.AddTransport(transport.POST{})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.Handle("/graphql", srv)

	log.Printf("GraphQL server listening on :%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
