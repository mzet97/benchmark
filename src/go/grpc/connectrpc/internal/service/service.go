package service

import (
	"benchmark-connectrpc/internal/canonical"
	"context"
	"fmt"
	"time"

	"benchmark-connectrpc/internal/cache"
	"benchmark-connectrpc/internal/db"

	benchmarkpb "benchmark-connectrpc/gen/benchmark"
	"connectrpc.com/connect"

	"github.com/google/uuid"
)

const version = "0.1.0"

// BenchmarkServiceHandler implements the ConnectRPC BenchmarkService handler.
type BenchmarkServiceHandler struct {
	db    *db.DB
	cache *cache.Cache
}

// New creates a new BenchmarkServiceHandler.
func New(d *db.DB, c *cache.Cache) *BenchmarkServiceHandler {
	return &BenchmarkServiceHandler{db: d, cache: c}
}

// Health implements BenchmarkServiceHandler.Health.
func (s *BenchmarkServiceHandler) Health(ctx context.Context, req *connect.Request[benchmarkpb.HealthRequest]) (*connect.Response[benchmarkpb.HealthResponse], error) {
	dbStatus := "connected"
	if err := s.db.Pool.Ping(ctx); err != nil {
		dbStatus = fmt.Sprintf("error: %v", err)
	}

	cacheStatus := "connected"
	if err := s.cache.Client.Ping(ctx).Err(); err != nil {
		cacheStatus = fmt.Sprintf("error: %v", err)
	}

	res := connect.NewResponse(&benchmarkpb.HealthResponse{
		Status:    "ok",
		Version:   version,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Database:  dbStatus,
		Cache:     cacheStatus,
	})
	return res, nil
}

// GetJsonItems implements BenchmarkServiceHandler.GetJsonItems.
func (s *BenchmarkServiceHandler) GetJsonItems(ctx context.Context, req *connect.Request[benchmarkpb.JsonItemsRequest]) (*connect.Response[benchmarkpb.JsonItemsResponse], error) {
	// The previous version minted a uuid.New() per item -- 1000 random
	// UUIDs per request -- stamped the clock into every CreatedAt and
	// used @example.com. See contracts/rest/canonical-payloads.md.
	limit := canonical.ItemCount(int(req.Msg.GetLimit()))

	items := make([]*benchmarkpb.JsonItem, limit)
	for i := 0; i < limit; i++ {
		items[i] = &benchmarkpb.JsonItem{
			Id:        int32(i),
			Uuid:      canonical.UUID(i),
			Name:      canonical.Name(i),
			Email:     canonical.Email(i),
			CreatedAt: canonical.CreatedAt,
			IsActive:  canonical.IsActive(i),
		}
	}

	// The envelope timestamp is the only clock-dependent field and is
	// excluded from the parity hash.
	now := time.Now().UTC().Format(time.RFC3339)

	res := connect.NewResponse(&benchmarkpb.JsonItemsResponse{
		Count:     int32(limit),
		Items:     items,
		Timestamp: now,
	})
	return res, nil
}

// GetUser implements BenchmarkServiceHandler.GetUser.
func (s *BenchmarkServiceHandler) GetUser(ctx context.Context, req *connect.Request[benchmarkpb.GetUserRequest]) (*connect.Response[benchmarkpb.UserResponse], error) {
	var user benchmarkpb.UserResponse
	var createdAt time.Time

	err := s.db.Pool.QueryRow(ctx,
		"SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
		req.Msg.GetId(),
	).Scan(&user.Id, &user.Email, &user.FirstName, &user.LastName, &user.Age, &createdAt)

	if err != nil {
		return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("user not found: %w", err))
	}

	user.CreatedAt = createdAt.Format(time.RFC3339)
	res := connect.NewResponse(&user)
	return res, nil
}

// GetComplexOrders implements BenchmarkServiceHandler.GetComplexOrders.
func (s *BenchmarkServiceHandler) GetComplexOrders(ctx context.Context, req *connect.Request[benchmarkpb.ComplexOrdersRequest]) (*connect.Response[benchmarkpb.ComplexOrdersResponse], error) {
	days := int(req.Msg.GetDays())
	if days <= 0 {
		days = 30
	}

	query := `
		-- Normative SQL, see contracts/rest/canonical-payloads.md. The previous
		-- query summed o.total, a column the schema does not have; it also ordered
		-- without a tiebreak, so rows with equal totals came back in arbitrary order.
		SELECT
		    u.id AS user_id,
		    u.first_name || ' ' || u.last_name AS user_name,
		    COUNT(o.id) AS total_orders,
		    COALESCE(SUM(o.total_amount), 0) AS total_value,
		    COALESCE(AVG(o.total_amount), 0) AS average_order_value
		FROM users u
		INNER JOIN orders o ON u.id = o.user_id
		    WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
		GROUP BY u.id, u.first_name, u.last_name
		ORDER BY total_orders DESC, u.id
		LIMIT 100
	`

	rows, err := s.db.Pool.Query(ctx, query, days)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("query error: %w", err))
	}
	defer rows.Close()

	var data []*benchmarkpb.UserOrderStats
	for rows.Next() {
		var stat benchmarkpb.UserOrderStats
		if err := rows.Scan(&stat.UserId, &stat.UserName, &stat.TotalOrders, &stat.TotalValue, &stat.AverageOrderValue); err != nil {
			return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("scan error: %w", err))
		}
		data = append(data, &stat)
	}

	if err := rows.Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("rows error: %w", err))
	}

	res := connect.NewResponse(&benchmarkpb.ComplexOrdersResponse{
		PeriodDays: int32(days),
		TotalUsers: int32(len(data)),
		Data:       data,
	})
	return res, nil
}

// GetCacheValue implements BenchmarkServiceHandler.GetCacheValue.
func (s *BenchmarkServiceHandler) GetCacheValue(ctx context.Context, req *connect.Request[benchmarkpb.CacheRequest]) (*connect.Response[benchmarkpb.CacheResponse], error) {
	key := fmt.Sprintf("benchmark:%s", req.Msg.GetKey())
	now := time.Now().UTC().Format(time.RFC3339)

	// Try cache hit
	val, err := s.cache.Client.Get(ctx, key).Result()
	if err == nil {
		ttl, _ := s.cache.Client.TTL(ctx, key).Result()
		res := connect.NewResponse(&benchmarkpb.CacheResponse{
			Key:       req.Msg.GetKey(),
			Value:     val,
			Cached:    true,
			Ttl:       int32(ttl.Seconds()),
			Timestamp: now,
		})
		return res, nil
	}

	// Cache miss: generate value and store
	value := fmt.Sprintf("value_%s", uuid.New().String())
	if err := s.cache.Client.Set(ctx, key, value, time.Hour).Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("redis error: %w", err))
	}

	res := connect.NewResponse(&benchmarkpb.CacheResponse{
		Key:       req.Msg.GetKey(),
		Value:     value,
		Cached:    false,
		Ttl:       3600,
		Timestamp: now,
	})
	return res, nil
}
