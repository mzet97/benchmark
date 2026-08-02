package db

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

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

type DB struct {
	pool *pgxpool.Pool
}

func New(ctx context.Context, databaseURL string) (*DB, error) {
	cfg, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse db url: %w", err)
	}
	cfg.MaxConns = 10

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping db: %w", err)
	}

	return &DB{pool: pool}, nil
}

func (d *DB) Close() {
	d.pool.Close()
}

func (d *DB) Ping(ctx context.Context) error {
	return d.pool.Ping(ctx)
}

func (d *DB) EnsureSchema(ctx context.Context) error {
	_, err := d.pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS users (
			id SERIAL PRIMARY KEY,
			email VARCHAR(255) NOT NULL,
			first_name VARCHAR(100) NOT NULL,
			last_name VARCHAR(100) NOT NULL,
			age INTEGER NOT NULL DEFAULT 0,
			created_at TIMESTAMP NOT NULL DEFAULT NOW()
		)
	`)
	if err != nil {
		return fmt.Errorf("create users table: %w", err)
	}

	_, err = d.pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS orders (
			id SERIAL PRIMARY KEY,
			user_id INTEGER NOT NULL REFERENCES users(id),
			amount NUMERIC(12,2) NOT NULL,
			status VARCHAR(50) NOT NULL DEFAULT 'completed',
			created_at TIMESTAMP NOT NULL DEFAULT NOW()
		)
	`)
	if err != nil {
		return fmt.Errorf("create orders table: %w", err)
	}

	// Seed data if empty
	var count int64
	err = d.pool.QueryRow(ctx, "SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil {
		return fmt.Errorf("count users: %w", err)
	}

	if count == 0 {
		_, err = d.pool.Exec(ctx, `
			INSERT INTO users (email, first_name, last_name, age)
			SELECT
				'user' || i || '@example.com',
				'First' || i,
				'Last' || i,
				20 + (i % 50)
			FROM generate_series(1, 100) AS s(i)
		`)
		if err != nil {
			return fmt.Errorf("seed users: %w", err)
		}

		_, err = d.pool.Exec(ctx, `
			INSERT INTO orders (user_id, amount, status, created_at)
			SELECT
				(i % 100) + 1,
				ROUND((random() * 500 + 10)::numeric, 2),
				CASE WHEN random() > 0.1 THEN 'completed' ELSE 'pending' END,
				NOW() - (random() * interval '90 days')
			FROM generate_series(1, 1000) AS s(i)
		`)
		if err != nil {
			return fmt.Errorf("seed orders: %w", err)
		}
	}

	return nil
}

func (d *DB) GetUser(ctx context.Context, id int) (*User, error) {
	row := d.pool.QueryRow(ctx,
		"SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1", id)

	var user User
	var createdAt time.Time
	err := row.Scan(&user.ID, &user.Email, &user.FirstName, &user.LastName, &user.Age, &createdAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get user: %w", err)
	}
	user.CreatedAt = createdAt.Format(time.RFC3339)
	return &user, nil
}

func (d *DB) GetComplexOrders(ctx context.Context, days int) ([]*UserOrderStats, error) {
	rows, err := d.pool.Query(ctx, `
		-- Normative SQL, see contracts/rest/canonical-payloads.md. The previous
		-- query aggregated o.amount / o.total, columns the schema does not have,
		-- ordered without a tiebreak, and in gqlgen had no LIMIT at all -- it
		-- returned every user, not the 100 the contract fixes, which changes the
		-- payload size and therefore the network ceiling of this scenario.
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
	`, days)
	if err != nil {
		return nil, fmt.Errorf("complex orders query: %w", err)
	}
	defer rows.Close()

	var results []*UserOrderStats
	for rows.Next() {
		var s UserOrderStats
		if err := rows.Scan(&s.UserID, &s.UserName, &s.TotalOrders, &s.TotalValue, &s.AverageOrderValue); err != nil {
			return nil, fmt.Errorf("scan order stats: %w", err)
		}
		results = append(results, &s)
	}
	return results, nil
}
