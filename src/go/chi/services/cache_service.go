package services

import (
	"context"
	"time"

	goredis "github.com/go-redis/redis/v8"
)

type CacheService struct {
	client *goredis.Client
}

func NewCacheService(client *goredis.Client) *CacheService {
	return &CacheService{client: client}
}

func (s *CacheService) GetOrSet(key string) (string, bool, error) {
	ctx := context.Background()

	value, err := s.client.Get(ctx, key).Result()
	if err == nil {
		return value, true, nil
	}

	newValue := "cached-value-" + key + "-" + time.Now().Format(time.RFC3339)
	err = s.client.Set(ctx, key, newValue, 300*time.Second).Err()
	if err != nil {
		return "", false, err
	}

	return newValue, false, nil
}

func (s *CacheService) Ping() error {
	ctx := context.Background()
	_, err := s.client.Ping(ctx).Result()
	return err
}
