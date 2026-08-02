package main

import (
	"context"
	"fmt"
	"graphql-graphql-go-2/internal/canonical"
	"time"

	"graphql-graphql-go-2/cache"
	"graphql-graphql-go-2/db"

	"github.com/graphql-go/graphql"
)

// Resolver holds the dependencies for GraphQL resolvers.
type Resolver struct {
	DB    *db.DB
	Cache *cache.Cache
}

// ResolveHealth handles the health query.
func (r *Resolver) ResolveHealth(p graphql.ResolveParams) (interface{}, error) {
	ctx := context.Background()

	dbStatus := "connected"
	if err := r.DB.Ping(ctx); err != nil {
		dbStatus = "disconnected"
	}

	cacheStatus := "connected"
	if err := r.Cache.Ping(ctx); err != nil {
		cacheStatus = "disconnected"
	}

	return map[string]interface{}{
		"status":    "ok",
		"version":   "1.0.0",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"database":  dbStatus,
		"cache":     cacheStatus,
	}, nil
}

// ResolveJsonItems handles the jsonItems query.
func (r *Resolver) ResolveJsonItems(p graphql.ResolveParams) (interface{}, error) {
	// The previous version built a "uuid-<n>-<nanos>" string, calling
	// time.Now().UnixNano() once per item -- 1000 high-resolution clock
	// reads per request -- numbered items from 1 and used @example.com.
	// See contracts/rest/canonical-payloads.md.
	count := canonical.DefaultItems
	if limit, ok := p.Args["limit"].(int); ok {
		count = canonical.ItemCount(limit)
	}

	items := make([]map[string]interface{}, count)
	for i := 0; i < count; i++ {
		items[i] = map[string]interface{}{
			"id":        i,
			"uuid":      canonical.UUID(i),
			"name":      canonical.Name(i),
			"email":     canonical.Email(i),
			"createdAt": canonical.CreatedAt,
			"isActive":  canonical.IsActive(i),
		}
	}

	// The envelope timestamp is the only clock-dependent field and is
	// excluded from the parity hash.
	now := time.Now().UTC().Format(time.RFC3339)

	return map[string]interface{}{
		"items":     items,
		"count":     count,
		"timestamp": now,
	}, nil
}

// ResolveUser handles the user query.
func (r *Resolver) ResolveUser(p graphql.ResolveParams) (interface{}, error) {
	ctx := context.Background()
	id := p.Args["id"].(int)

	user, err := r.DB.GetUser(ctx, id)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, nil
	}

	return map[string]interface{}{
		"id":        user.ID,
		"email":     user.Email,
		"firstName": user.FirstName,
		"lastName":  user.LastName,
		"age":       user.Age,
		"createdAt": user.CreatedAt,
	}, nil
}

// ResolveComplexOrders handles the complexOrders query.
func (r *Resolver) ResolveComplexOrders(p graphql.ResolveParams) (interface{}, error) {
	ctx := context.Background()
	periodDays := 30
	if days, ok := p.Args["days"].(int); ok {
		periodDays = days
	}

	data, err := r.DB.GetComplexOrders(ctx, periodDays)
	if err != nil {
		return nil, err
	}

	stats := make([]map[string]interface{}, len(data))
	for i, s := range data {
		stats[i] = map[string]interface{}{
			"userId":            s.UserID,
			"userName":          s.UserName,
			"totalOrders":       s.TotalOrders,
			"totalValue":        s.TotalValue,
			"averageOrderValue": s.AverageOrderValue,
		}
	}

	return map[string]interface{}{
		"periodDays": periodDays,
		"totalUsers": len(data),
		"data":       stats,
	}, nil
}

// ResolveCache handles the cache query.
func (r *Resolver) ResolveCache(p graphql.ResolveParams) (interface{}, error) {
	ctx := context.Background()
	key := p.Args["key"].(string)

	val, ttl, err := r.Cache.Get(ctx, key)
	if err == nil && val != "" {
		return map[string]interface{}{
			"key":    key,
			"value":  val,
			"cached": true,
			"ttl":    int(ttl.Seconds()),
		}, nil
	}

	// Generate value on miss
	value := fmt.Sprintf("value-for-%s", key)
	_ = r.Cache.Set(ctx, key, value, 300*time.Second)

	return map[string]interface{}{
		"key":    key,
		"value":  value,
		"cached": false,
		"ttl":    300,
	}, nil
}
