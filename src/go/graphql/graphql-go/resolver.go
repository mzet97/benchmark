package main

import (
	"context"
	"fmt"
	"time"

	"graphql-graphql-go/cache"
	"graphql-graphql-go/db"
)

// Resolver is the root resolver for the GraphQL schema.
type Resolver struct {
	DB    *db.DB
	Cache *cache.Cache
}

// Health resolves the health query.
func (r *Resolver) Health(ctx context.Context) (*Health, error) {
	dbStatus := "connected"
	if err := r.DB.Ping(ctx); err != nil {
		dbStatus = "disconnected"
	}

	cacheStatus := "connected"
	if err := r.Cache.Ping(ctx); err != nil {
		cacheStatus = "disconnected"
	}

	return &Health{
		Status:    "ok",
		Version:   "1.0.0",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Database:  dbStatus,
		Cache:     cacheStatus,
	}, nil
}

// JsonItems resolves the jsonItems query.
func (r *Resolver) JsonItems(ctx context.Context, args struct{ Limit *int32 }) (*JsonItemsResult, error) {
	count := 1000
	if args.Limit != nil {
		count = int(*args.Limit)
	}

	items := make([]*JsonItem, count)
	now := time.Now().UTC().Format(time.RFC3339)
	for i := 0; i < count; i++ {
		items[i] = &JsonItem{
			ID:        int32(i + 1),
			UUID:      fmt.Sprintf("uuid-%d-%d", i+1, time.Now().UnixNano()),
			Name:      fmt.Sprintf("Item %d", i+1),
			Email:     fmt.Sprintf("item%d@example.com", i+1),
			CreatedAt: now,
			IsActive:  i%2 == 0,
		}
	}

	return &JsonItemsResult{
		Items:     items,
		Count:     int32(count),
		Timestamp: now,
	}, nil
}

// User resolves the user query.
func (r *Resolver) User(ctx context.Context, args struct{ ID int32 }) (*User, error) {
	user, err := r.DB.GetUser(ctx, int(args.ID))
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, nil
	}
	return user, nil
}

// ComplexOrders resolves the complexOrders query.
func (r *Resolver) ComplexOrders(ctx context.Context, args struct{ Days *int32 }) (*ComplexOrdersResult, error) {
	periodDays := 30
	if args.Days != nil {
		periodDays = int(*args.Days)
	}

	data, err := r.DB.GetComplexOrders(ctx, periodDays)
	if err != nil {
		return nil, err
	}

	return &ComplexOrdersResult{
		PeriodDays: int32(periodDays),
		TotalUsers: int32(len(data)),
		Data:       data,
	}, nil
}

// Cache resolves the cache query.
func (r *Resolver) Cache(ctx context.Context, args struct{ Key string }) (*CacheEntry, error) {
	val, ttl, err := r.Cache.Get(ctx, args.Key)
	if err == nil && val != "" {
		return &CacheEntry{
			Key:    args.Key,
			Value:  val,
			Cached: true,
			TTL:    int32(ttl.Seconds()),
		}, nil
	}

	// Generate value on miss
	value := fmt.Sprintf("value-for-%s", args.Key)
	_ = r.Cache.Set(ctx, args.Key, value, 300*time.Second)

	return &CacheEntry{
		Key:    args.Key,
		Value:  value,
		Cached: false,
		TTL:    300,
	}, nil
}

// GraphQL types matching the schema.
type Health struct {
	Status    string
	Version   string
	Timestamp string
	Database  string
	Cache     string
}

type JsonItem struct {
	ID        int32
	UUID      string
	Name      string
	Email     string
	CreatedAt string
	IsActive  bool
}

type JsonItemsResult struct {
	Items     []*JsonItem
	Count     int32
	Timestamp string
}

type User struct {
	ID        int32
	Email     string
	FirstName string
	LastName  string
	Age       int32
	CreatedAt string
}

type UserOrderStats struct {
	UserID            int32
	UserName          string
	TotalOrders       int32
	TotalValue        float64
	AverageOrderValue float64
}

type ComplexOrdersResult struct {
	PeriodDays int32
	TotalUsers int32
	Data       []*UserOrderStats
}

type CacheEntry struct {
	Key    string
	Value  string
	Cached bool
	TTL    int32
}
