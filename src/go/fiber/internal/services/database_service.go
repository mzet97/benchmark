package services

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/benchmark/go-fiber/internal/models"
	"github.com/jackc/pgx/v5"
)

// DatabaseService handles all database operations
type DatabaseService struct {
	conn *pgx.Conn
	ctx  context.Context
}

// NewDatabaseService creates a new DatabaseService instance
func NewDatabaseService(conn *pgx.Conn) *DatabaseService {
	return &DatabaseService{
		conn: conn,
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

	row := ds.conn.QueryRow(ds.ctx, query, id)
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
	query := `
		SELECT
			u.id as user_id,
			u.email,
			COUNT(o.id) as order_count,
			SUM(o.total_amount) as total_amount,
			AVG(o.total_amount) as avg_amount,
			EXTRACT(DAY FROM (NOW() - MIN(o.created_at))) as days_since_first_order
		FROM users u
		INNER JOIN orders o ON u.id = o.user_id
		WHERE o.created_at >= NOW() - ($1 || ' days')::INTERVAL
		GROUP BY u.id, u.email
		ORDER BY order_count DESC
		LIMIT 100
	`

	rows, err := ds.conn.Query(ds.ctx, query, days)
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
			&result.Email,
			&result.OrderCount,
			&result.TotalAmount,
			&result.AverageAmount,
			&result.DaysSinceFirstOrder,
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
	err := ds.conn.QueryRow(ds.ctx, query).Scan(&result)
	if err != nil {
		log.Printf("Database health check failed: %v", err)
		return false
	}
	return result == 1
}

// Close closes the database connection
func (ds *DatabaseService) Close() {
	if ds.conn != nil {
		ds.conn.Close(ds.ctx)
	}
}
