package service

import (
	"benchmark-kitex/internal/canonical"
	"context"
	"fmt"
	"time"

	"benchmark-kitex/internal/cache"
	"benchmark-kitex/internal/db"

	"github.com/google/uuid"
)

const version = "0.1.0"

// ---------------------------------------------------------------------------
// Placeholder message types
// Kitex code generation (kitex tool) produces these in kitex_gen/benchmark/.
// Until codegen runs, these local types let the project compile and are
// structurally identical to the generated ones.
// ---------------------------------------------------------------------------

type HealthRequest struct{}

type HealthResponse struct {
	Status    string `thrift:"status,1" json:"status"`
	Version   string `thrift:"version,2" json:"version"`
	Timestamp string `thrift:"timestamp,3" json:"timestamp"`
	Database  string `thrift:"database,4" json:"database"`
	Cache     string `thrift:"cache,5" json:"cache"`
}

type JsonItemsRequest struct {
	Limit int32 `thrift:"limit,1" json:"limit"`
}

type JsonItemsResponse struct {
	Items     []*JsonItem `thrift:"items,1" json:"items"`
	Count     int32       `thrift:"count,2" json:"count"`
	Timestamp string      `thrift:"timestamp,3" json:"timestamp"`
}

type JsonItem struct {
	Id        int32  `thrift:"id,1" json:"id"`
	Uuid      string `thrift:"uuid,2" json:"uuid"`
	Name      string `thrift:"name,3" json:"name"`
	Email     string `thrift:"email,4" json:"email"`
	CreatedAt string `thrift:"created_at,5" json:"created_at"`
	IsActive  bool   `thrift:"is_active,6" json:"is_active"`
}

type GetUserRequest struct {
	Id int32 `thrift:"id,1" json:"id"`
}

type UserResponse struct {
	Id        int32  `thrift:"id,1" json:"id"`
	Email     string `thrift:"email,2" json:"email"`
	FirstName string `thrift:"first_name,3" json:"first_name"`
	LastName  string `thrift:"last_name,4" json:"last_name"`
	Age       int32  `thrift:"age,5" json:"age"`
	CreatedAt string `thrift:"created_at,6" json:"created_at"`
}

type ComplexOrdersRequest struct {
	Days int32 `thrift:"days,1" json:"days"`
}

type ComplexOrdersResponse struct {
	PeriodDays int32             `thrift:"period_days,1" json:"period_days"`
	TotalUsers int32             `thrift:"total_users,2" json:"total_users"`
	Data       []*UserOrderStats `thrift:"data,3" json:"data"`
}

type UserOrderStats struct {
	UserId            int32   `thrift:"user_id,1" json:"user_id"`
	UserName          string  `thrift:"user_name,2" json:"user_name"`
	TotalOrders       int32   `thrift:"total_orders,3" json:"total_orders"`
	TotalValue        float64 `thrift:"total_value,4" json:"total_value"`
	AverageOrderValue float64 `thrift:"average_order_value,5" json:"average_order_value"`
}

type CacheRequest struct {
	Key string `thrift:"key,1" json:"key"`
}

type CacheResponse struct {
	Key       string `thrift:"key,1" json:"key"`
	Value     string `thrift:"value,2" json:"value"`
	Cached    bool   `thrift:"cached,3" json:"cached"`
	Ttl       int32  `thrift:"ttl,4" json:"ttl"`
	Timestamp string `thrift:"timestamp,5" json:"timestamp"`
}

// ---------------------------------------------------------------------------
// Service implementation
// ---------------------------------------------------------------------------

// BenchmarkServiceImpl implements the Kitex BenchmarkService.
// Once kitex_gen is generated, the handler registration in main.go will
// wire this implementation to the Kitex-generated service server.
type BenchmarkServiceImpl struct {
	db    *db.DB
	cache *cache.Cache
}

// New creates a new BenchmarkServiceImpl.
func New(d *db.DB, c *cache.Cache) *BenchmarkServiceImpl {
	return &BenchmarkServiceImpl{db: d, cache: c}
}

// Health implements the Health RPC.
func (s *BenchmarkServiceImpl) Health(ctx context.Context, req *HealthRequest) (*HealthResponse, error) {
	dbStatus := "connected"
	if err := s.db.Pool.Ping(ctx); err != nil {
		dbStatus = fmt.Sprintf("error: %v", err)
	}

	cacheStatus := "connected"
	if err := s.cache.Client.Ping(ctx).Err(); err != nil {
		cacheStatus = fmt.Sprintf("error: %v", err)
	}

	return &HealthResponse{
		Status:    "ok",
		Version:   version,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Database:  dbStatus,
		Cache:     cacheStatus,
	}, nil
}

// GetJsonItems implements the GetJsonItems RPC.
func (s *BenchmarkServiceImpl) GetJsonItems(ctx context.Context, req *JsonItemsRequest) (*JsonItemsResponse, error) {
	// The previous version minted a uuid.New() per item -- 1000 random
	// UUIDs per request -- stamped the clock into every CreatedAt and
	// used @example.com. See contracts/rest/canonical-payloads.md.
	limit := canonical.ItemCount(int(req.GetLimit()))

	items := make([]*JsonItem, limit)
	for i := 0; i < limit; i++ {
		items[i] = &JsonItem{
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

	return &JsonItemsResponse{
		Count:     int32(limit),
		Items:     items,
		Timestamp: now,
	}, nil
}

// GetUser implements the GetUser RPC.
func (s *BenchmarkServiceImpl) GetUser(ctx context.Context, req *GetUserRequest) (*UserResponse, error) {
	var user UserResponse
	var createdAt time.Time

	err := s.db.Pool.QueryRow(ctx,
		"SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
		req.GetId(),
	).Scan(&user.Id, &user.Email, &user.FirstName, &user.LastName, &user.Age, &createdAt)

	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}

	user.CreatedAt = createdAt.Format(time.RFC3339)
	return &user, nil
}

// GetComplexOrders implements the GetComplexOrders RPC.
func (s *BenchmarkServiceImpl) GetComplexOrders(ctx context.Context, req *ComplexOrdersRequest) (*ComplexOrdersResponse, error) {
	days := int(req.GetDays())
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
		return nil, fmt.Errorf("query error: %w", err)
	}
	defer rows.Close()

	var data []*UserOrderStats
	for rows.Next() {
		var stat UserOrderStats
		if err := rows.Scan(&stat.UserId, &stat.UserName, &stat.TotalOrders, &stat.TotalValue, &stat.AverageOrderValue); err != nil {
			return nil, fmt.Errorf("scan error: %w", err)
		}
		data = append(data, &stat)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows error: %w", err)
	}

	return &ComplexOrdersResponse{
		PeriodDays: int32(days),
		TotalUsers: int32(len(data)),
		Data:       data,
	}, nil
}

// GetCacheValue implements the GetCacheValue RPC.
func (s *BenchmarkServiceImpl) GetCacheValue(ctx context.Context, req *CacheRequest) (*CacheResponse, error) {
	key := fmt.Sprintf("benchmark:%s", req.GetKey())
	now := time.Now().UTC().Format(time.RFC3339)

	// Try cache hit
	val, err := s.cache.Client.Get(ctx, key).Result()
	if err == nil {
		ttl, _ := s.cache.Client.TTL(ctx, key).Result()
		return &CacheResponse{
			Key:       req.GetKey(),
			Value:     val,
			Cached:    true,
			Ttl:       int32(ttl.Seconds()),
			Timestamp: now,
		}, nil
	}

	// Cache miss: generate value and store
	value := fmt.Sprintf("value_%s", uuid.New().String())
	if err := s.cache.Client.Set(ctx, key, value, time.Hour).Err(); err != nil {
		return nil, fmt.Errorf("redis error: %w", err)
	}

	return &CacheResponse{
		Key:       req.GetKey(),
		Value:     value,
		Cached:    false,
		Ttl:       3600,
		Timestamp: now,
	}, nil
}
