package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"graphql-graphql-go-2/cache"
	"graphql-graphql-go-2/db"

	"github.com/graphql-go/handler"
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

	// Create schema with resolvers
	schema, err := NewSchema(database, cacheClient)
	if err != nil {
		log.Fatalf("Failed to create schema: %v", err)
	}

	// Create GraphQL handler - POST only, no playground, no introspection
	h := handler.New(&handler.Config{
		Schema:     schema,
		Pretty:     false,
		GraphiQL:   false,
		Playground: false,
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/graphql", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		h.ServeHTTP(w, r)
	})

	log.Printf("GraphQL server (graphql-go) listening on :%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
