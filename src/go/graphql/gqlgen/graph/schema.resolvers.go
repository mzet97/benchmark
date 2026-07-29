package graph

// This file will be automatically regenerated based on the schema, any resolver implementations
// will be copied through when generating and any unknown code will be moved to the end.

import (
	"context"
	"fmt"
	"time"

	"graphql-gqlgen/graph/model"
)

// Health is the resolver for the health field.
func (r *queryResolver) Health(ctx context.Context) (*model.Health, error) {
	dbStatus := "connected"
	if err := r.DB.Ping(ctx); err != nil {
		dbStatus = "disconnected"
	}

	cacheStatus := "connected"
	if err := r.Cache.Ping(ctx); err != nil {
		cacheStatus = "disconnected"
	}

	return &model.Health{
		Status:    "ok",
		Version:   "1.0.0",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Database:  dbStatus,
		Cache:     cacheStatus,
	}, nil
}

// JsonItems is the resolver for the jsonItems field.
func (r *queryResolver) JsonItems(ctx context.Context, limit *int) (*model.JsonItemsResult, error) {
	count := 1000
	if limit != nil {
		count = *limit
	}

	items := make([]*model.JsonItem, count)
	now := time.Now().UTC().Format(time.RFC3339)
	for i := 0; i < count; i++ {
		items[i] = &model.JsonItem{
			ID:        i + 1,
			UUID:      fmt.Sprintf("uuid-%d-%d", i+1, time.Now().UnixNano()),
			Name:      fmt.Sprintf("Item %d", i+1),
			Email:     fmt.Sprintf("item%d@example.com", i+1),
			CreatedAt: now,
			IsActive:  i%2 == 0,
		}
	}

	return &model.JsonItemsResult{
		Items:     items,
		Count:     count,
		Timestamp: now,
	}, nil
}

// User is the resolver for the user field.
func (r *queryResolver) User(ctx context.Context, id int) (*model.User, error) {
	user, err := r.DB.GetUser(ctx, id)
	if err != nil {
		return nil, err
	}
	return user, nil
}

// ComplexOrders is the resolver for the complexOrders field.
func (r *queryResolver) ComplexOrders(ctx context.Context, days *int) (*model.ComplexOrdersResult, error) {
	periodDays := 30
	if days != nil {
		periodDays = *days
	}

	data, err := r.DB.GetComplexOrders(ctx, periodDays)
	if err != nil {
		return nil, err
	}

	return &model.ComplexOrdersResult{
		PeriodDays: periodDays,
		TotalUsers: len(data),
		Data:       data,
	}, nil
}

// Cache is the resolver for the cache field.
func (r *queryResolver) Cache(ctx context.Context, key string) (*model.CacheEntry, error) {
	// Try to get from cache
	val, ttl, err := r.Cache.Get(ctx, key)
	if err == nil && val != "" {
		return &model.CacheEntry{
			Key:    key,
			Value:  val,
			Cached: true,
			TTL:    int(ttl.Seconds()),
		}, nil
	}

	// Generate value on miss
	value := fmt.Sprintf("value-for-%s", key)
	_ = r.Cache.Set(ctx, key, value, 300*time.Second)

	return &model.CacheEntry{
		Key:    key,
		Value:  value,
		Cached: false,
		TTL:    300,
	}, nil
}

// Query returns QueryResolver implementation.
func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type queryResolver struct{ *Resolver }
