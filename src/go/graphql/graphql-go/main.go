package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"graphql-graphql-go/cache"
	"graphql-graphql-go/db"

	graphql "github.com/graph-gophers/graphql-go"
	"github.com/graph-gophers/graphql-go/relay"
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

	// Parse schema and create resolver
	s, err := graphql.ParseSchema(schemaString, &Resolver{
		DB:    database,
		Cache: cacheClient,
	})
	if err != nil {
		log.Fatalf("Failed to parse schema: %v", err)
	}

	// Create HTTP handler - POST only, no playground
	h := &relay.Handler{Schema: s}

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

	log.Printf("GraphQL server (graph-gophers) listening on :%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

const schemaString = `
	schema {
		query: Query
	}

	type Query {
		health: Health!
		jsonItems(limit: Int = 1000): JsonItemsResult!
		user(id: Int!): User
		complexOrders(days: Int = 30): ComplexOrdersResult!
		cache(key: String!): CacheEntry!
	}

	type Health {
		status: String!
		version: String!
		timestamp: String!
		database: String!
		cache: String!
	}

	type JsonItem {
		id: Int!
		uuid: String!
		name: String!
		email: String!
		createdAt: String!
		isActive: Boolean!
	}

	type JsonItemsResult {
		items: [JsonItem!]!
		count: Int!
		timestamp: String!
	}

	type User {
		id: Int!
		email: String!
		firstName: String!
		lastName: String!
		age: Int!
		createdAt: String!
	}

	type UserOrderStats {
		userId: Int!
		userName: String!
		totalOrders: Int!
		totalValue: Float!
		averageOrderValue: Float!
	}

	type ComplexOrdersResult {
		periodDays: Int!
		totalUsers: Int!
		data: [UserOrderStats!]!
	}

	type CacheEntry {
		key: String!
		value: String!
		cached: Boolean!
		ttl: Int!
	}
`
