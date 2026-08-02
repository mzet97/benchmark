package main

import (
	"graphql-graphql-go-2/cache"
	"graphql-graphql-go-2/db"

	"github.com/graphql-go/graphql"
)

// NewSchema creates the GraphQL schema with all types and resolvers.
func NewSchema(database *db.DB, cacheClient *cache.Cache) (*graphql.Schema, error) {
	resolvers := &Resolver{
		DB:    database,
		Cache: cacheClient,
	}

	// Define types
	healthType := graphql.NewObject(graphql.ObjectConfig{
		Name: "Health",
		Fields: graphql.Fields{
			"status":    &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"version":   &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"timestamp": &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"database":  &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"cache":     &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
		},
	})

	jsonItemType := graphql.NewObject(graphql.ObjectConfig{
		Name: "JsonItem",
		Fields: graphql.Fields{
			"id":        &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
			"uuid":      &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"name":      &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"email":     &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"createdAt": &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"isActive":  &graphql.Field{Type: graphql.NewNonNull(graphql.Boolean)},
		},
	})

	jsonItemsResultType := graphql.NewObject(graphql.ObjectConfig{
		Name: "JsonItemsResult",
		Fields: graphql.Fields{
			"items":     &graphql.Field{Type: graphql.NewNonNull(graphql.NewList(graphql.NewNonNull(jsonItemType)))},
			"count":     &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
			"timestamp": &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
		},
	})

	userType := graphql.NewObject(graphql.ObjectConfig{
		Name: "User",
		Fields: graphql.Fields{
			"id":        &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
			"email":     &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"firstName": &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"lastName":  &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"age":       &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
			"createdAt": &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
		},
	})

	userOrderStatsType := graphql.NewObject(graphql.ObjectConfig{
		Name: "UserOrderStats",
		Fields: graphql.Fields{
			"userId":            &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
			"userName":          &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"totalOrders":       &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
			"totalValue":        &graphql.Field{Type: graphql.NewNonNull(graphql.Float)},
			"averageOrderValue": &graphql.Field{Type: graphql.NewNonNull(graphql.Float)},
		},
	})

	complexOrdersResultType := graphql.NewObject(graphql.ObjectConfig{
		Name: "ComplexOrdersResult",
		Fields: graphql.Fields{
			"periodDays": &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
			"totalUsers": &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
			"data":       &graphql.Field{Type: graphql.NewNonNull(graphql.NewList(graphql.NewNonNull(userOrderStatsType)))},
		},
	})

	cacheEntryType := graphql.NewObject(graphql.ObjectConfig{
		Name: "CacheEntry",
		Fields: graphql.Fields{
			"key":    &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"value":  &graphql.Field{Type: graphql.NewNonNull(graphql.String)},
			"cached": &graphql.Field{Type: graphql.NewNonNull(graphql.Boolean)},
			"ttl":    &graphql.Field{Type: graphql.NewNonNull(graphql.Int)},
		},
	})

	// Define query type
	queryType := graphql.NewObject(graphql.ObjectConfig{
		Name: "Query",
		Fields: graphql.Fields{
			"health": &graphql.Field{
				Type:    graphql.NewNonNull(healthType),
				Resolve: resolvers.ResolveHealth,
			},
			"jsonItems": &graphql.Field{
				Type: graphql.NewNonNull(jsonItemsResultType),
				Args: graphql.FieldConfigArgument{
					"limit": &graphql.ArgumentConfig{
						Type:         graphql.Int,
						DefaultValue: 1000,
					},
				},
				Resolve: resolvers.ResolveJsonItems,
			},
			"user": &graphql.Field{
				Type: userType,
				Args: graphql.FieldConfigArgument{
					"id": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.Int),
					},
				},
				Resolve: resolvers.ResolveUser,
			},
			"complexOrders": &graphql.Field{
				Type: graphql.NewNonNull(complexOrdersResultType),
				Args: graphql.FieldConfigArgument{
					"days": &graphql.ArgumentConfig{
						Type:         graphql.Int,
						DefaultValue: 30,
					},
				},
				Resolve: resolvers.ResolveComplexOrders,
			},
			"cache": &graphql.Field{
				Type: graphql.NewNonNull(cacheEntryType),
				Args: graphql.FieldConfigArgument{
					"key": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.String),
					},
				},
				Resolve: resolvers.ResolveCache,
			},
		},
	})

	schema, err := graphql.NewSchema(graphql.SchemaConfig{
		Query: queryType,
	})
	if err != nil {
		return nil, err
	}

	return &schema, nil
}
