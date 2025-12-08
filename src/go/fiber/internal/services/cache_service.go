package services

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
)

// CacheService handles all cache operations
type CacheService struct {
	client *redis.Client
	ctx    context.Context
}

// NewCacheService creates a new CacheService instance
func NewCacheService(client *redis.Client) *CacheService {
	return &CacheService{
		client: client,
		ctx:    context.Background(),
	}
}

// Get retrieves a value from cache
func (cs *CacheService) Get(key string) (string, error) {
	val, err := cs.client.Get(cs.ctx, key).Result()
	if err != nil {
		if err == redis.Nil {
			return "", fmt.Errorf("key not found")
		}
		log.Printf("Error getting cache key %s: %v", key, err)
		return "", err
	}
	return val, nil
}

// Set sets a value in cache with TTL
func (cs *CacheService) Set(key, value string, ttl time.Duration) error {
	err := cs.client.Set(cs.ctx, key, value, ttl).Err()
	if err != nil {
		log.Printf("Error setting cache key %s: %v", key, err)
		return err
	}
	return nil
}

// GetOrSet retrieves value from cache or sets a new one
func (cs *CacheService) GetOrSet(key, newValue string, ttl time.Duration) (string, error) {
	val, err := cs.Get(key)
	if err != nil {
		log.Printf("Cache miss for key: %s", key)
		if err := cs.Set(key, newValue, ttl); err != nil {
			return "", err
		}
		return newValue, nil
	}
	log.Printf("Cache hit for key: %s", key)
	return val, nil
}

// HealthCheck performs a cache health check
func (cs *CacheService) HealthCheck() bool {
	_, err := cs.client.Ping(cs.ctx).Result()
	if err != nil {
		log.Printf("Cache health check failed: %v", err)
		return false
	}
	return true
}

// Close closes the cache connection
func (cs *CacheService) Close() error {
	if cs.client != nil {
		return cs.client.Close()
	}
	return nil
}
