package service

import (
	"context"
	"fmt"
	"time"

	"benchmark-grpc-go/internal/cache"
	"benchmark-grpc-go/internal/db"
	pb "benchmark-grpc-go/proto/generated"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const version = "0.1.0"

type BenchmarkService struct {
	pb.UnimplementedBenchmarkServiceServer
	db    *db.DB
	cache *cache.Cache
}

func New(d *db.DB, c *cache.Cache) *BenchmarkService {
	return &BenchmarkService{db: d, cache: c}
}

func (s *BenchmarkService) Health(ctx context.Context, req *pb.HealthRequest) (*pb.HealthResponse, error) {
	dbStatus := "connected"
	if err := s.db.Pool.Ping(ctx); err != nil {
		dbStatus = fmt.Sprintf("error: %v", err)
	}

	cacheStatus := "connected"
	if err := s.cache.Client.Ping(ctx).Err(); err != nil {
		cacheStatus = fmt.Sprintf("error: %v", err)
	}

	return &pb.HealthResponse{
		Status:    "ok",
		Version:   version,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Database:  dbStatus,
		Cache:     cacheStatus,
	}, nil
}

func (s *BenchmarkService) GetJsonItems(ctx context.Context, req *pb.JsonItemsRequest) (*pb.JsonItemsResponse, error) {
	limit := int(req.Limit)
	if limit <= 0 {
		limit = 1000
	}

	items := make([]*pb.JsonItem, limit)
	now := time.Now().UTC().Format(time.RFC3339)

	for i := 0; i < limit; i++ {
		items[i] = &pb.JsonItem{
			Id:        int32(i),
			Uuid:      uuid.New().String(),
			Name:      fmt.Sprintf("Item %d", i),
			Email:     fmt.Sprintf("item%d@example.com", i),
			CreatedAt: now,
			IsActive:  i%2 == 0,
		}
	}

	return &pb.JsonItemsResponse{
		Count:     int32(limit),
		Items:     items,
		Timestamp: now,
	}, nil
}

func (s *BenchmarkService) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.UserResponse, error) {
	var user pb.UserResponse
	var createdAt time.Time

	err := s.db.Pool.QueryRow(ctx,
		"SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
		req.Id,
	).Scan(&user.Id, &user.Email, &user.FirstName, &user.LastName, &user.Age, &createdAt)

	if err != nil {
		return nil, status.Errorf(codes.NotFound, "user not found: %v", err)
	}

	user.CreatedAt = createdAt.Format(time.RFC3339)
	return &user, nil
}

func (s *BenchmarkService) GetComplexOrders(ctx context.Context, req *pb.ComplexOrdersRequest) (*pb.ComplexOrdersResponse, error) {
	days := int(req.Days)
	if days <= 0 {
		days = 30
	}

	query := `
		SELECT u.id, u.first_name || ' ' || u.last_name AS user_name,
			COUNT(o.id) AS total_orders,
			COALESCE(SUM(o.total), 0) AS total_value,
			COALESCE(AVG(o.total), 0) AS average_order_value
		FROM users u
		LEFT JOIN orders o ON o.user_id = u.id
			AND o.created_at >= NOW() - ($1 || ' days')::interval
		GROUP BY u.id, user_name
		ORDER BY total_value DESC
		LIMIT 100
	`

	rows, err := s.db.Pool.Query(ctx, query, fmt.Sprintf("%d", days))
	if err != nil {
		return nil, status.Errorf(codes.Internal, "query error: %v", err)
	}
	defer rows.Close()

	var data []*pb.UserOrderStats
	for rows.Next() {
		var stat pb.UserOrderStats
		if err := rows.Scan(&stat.UserId, &stat.UserName, &stat.TotalOrders, &stat.TotalValue, &stat.AverageOrderValue); err != nil {
			return nil, status.Errorf(codes.Internal, "scan error: %v", err)
		}
		data = append(data, &stat)
	}

	if err := rows.Err(); err != nil {
		return nil, status.Errorf(codes.Internal, "rows error: %v", err)
	}

	return &pb.ComplexOrdersResponse{
		PeriodDays: int32(days),
		TotalUsers: int32(len(data)),
		Data:       data,
	}, nil
}

func (s *BenchmarkService) GetCacheValue(ctx context.Context, req *pb.CacheRequest) (*pb.CacheResponse, error) {
	key := fmt.Sprintf("benchmark:%s", req.Key)
	now := time.Now().UTC().Format(time.RFC3339)

	// Try cache hit
	val, err := s.cache.Client.Get(ctx, key).Result()
	if err == nil {
		ttl, _ := s.cache.Client.TTL(ctx, key).Result()
		return &pb.CacheResponse{
			Key:       req.Key,
			Value:     val,
			Cached:    true,
			Ttl:       int32(ttl.Seconds()),
			Timestamp: now,
		}, nil
	}

	// Cache miss: generate value and store
	value := fmt.Sprintf("value_%s", uuid.New().String())
	if err := s.cache.Client.Set(ctx, key, value, time.Hour).Err(); err != nil {
		return nil, status.Errorf(codes.Internal, "redis error: %v", err)
	}

	return &pb.CacheResponse{
		Key:       req.Key,
		Value:     value,
		Cached:    false,
		Ttl:       3600,
		Timestamp: now,
	}, nil
}
