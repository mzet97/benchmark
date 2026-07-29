package graph

import (
	"graphql-gqlgen/cache"
	"graphql-gqlgen/db"
)

// Resolver is the root resolver for the GraphQL schema.
type Resolver struct {
	DB    *db.DB
	Cache *cache.Cache
}
