package services

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/benchmark/go-fiber/internal/models"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// DatabaseService handles all database operations.
//
// Backed by a pool, not a single connection. The previous version held one
// *pgx.Conn, which serialises every query onto a single session -- a
// different DB access model from every other implementation in this
// benchmark, and therefore not comparable.
type DatabaseService struct {
	pool *pgxpool.Pool
	ctx  context.Context
}

// NewDatabaseService creates a new DatabaseService instance
func NewDatabaseService(pool *pgxpool.Pool) *DatabaseService {
	return &DatabaseService{
		pool: pool,
		ctx:  context.Background(),
	}
}

// FindUserByID retrieves a user by ID
func (ds *DatabaseService) FindUserByID(id int) (*models.User, error) {
	query := `
		SELECT id, email, first_name, last_name, age, created_at
		FROM users
		WHERE id = $1
	`

	row := ds.pool.QueryRow(ds.ctx, query, id)
	var user models.User
	var createdAt time.Time

	err := row.Scan(
		&user.ID,
		&user.Email,
		&user.FirstName,
		&user.LastName,
		&user.Age,
		&createdAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		log.Printf("Error scanning user: %v", err)
		return nil, err
	}

	user.CreatedAt = createdAt
	return &user, nil
}

// FindComplexOrders retrieves aggregated order statistics
func (ds *DatabaseService) FindComplexOrders(days int) ([]*models.ComplexOrderResult, error) {
	// Mirrors UserOrderStats in contracts/grpc/benchmark.proto. The LIMIT is
	// part of the contract: changing it changes the payload size and therefore
	// the network ceiling of this scenario.
	//
	// ORDER BY includes u.id to break ties deterministically -- without it,
	// rows with equal order counts come back in arbitrary order and the
	// response is not reproducible between runs.
	query := `
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

	rows, err := ds.pool.Query(ds.ctx, query, days)
	if err != nil {
		log.Printf("Error querying complex orders: %v", err)
		return nil, err
	}
	defer rows.Close()

	var results []*models.ComplexOrderResult
	for rows.Next() {
		var result models.ComplexOrderResult
		err := rows.Scan(
			&result.UserID,
			&result.UserName,
			&result.TotalOrders,
			&result.TotalValue,
			&result.AverageOrderValue,
		)
		if err != nil {
			log.Printf("Error scanning complex order result: %v", err)
			continue
		}
		results = append(results, &result)
	}

	return results, nil
}

// HealthCheck performs a database health check
func (ds *DatabaseService) HealthCheck() bool {
	query := "SELECT 1"
	var result int
	err := ds.pool.QueryRow(ds.ctx, query).Scan(&result)
	if err != nil {
		log.Printf("Database health check failed: %v", err)
		return false
	}
	return result == 1
}

// Close closes the database connection
func (ds *DatabaseService) Close() {
	if ds.pool != nil {
		ds.pool.Close()
	}
}
