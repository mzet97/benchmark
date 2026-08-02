package graph

import (
	"graphql-gqlgen/cache"
	"graphql-gqlgen/db"
)

// Resolver is the root resolver for the GraphQL schema.
// CacheSvc, not Cache: the resolver method for the `cache` query is also
// called Cache, and a Go struct cannot carry a field and a method with the
// same name -- every r.CacheSvc.* call resolved to the method value instead,
// so neither package compiled.
type Resolver struct {
	DB       *db.DB
	CacheSvc *cache.Cache
}
