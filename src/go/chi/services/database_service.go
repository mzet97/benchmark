package services

import (
	"database/sql"
	"log"

	"chi/models"
)

type DatabaseService struct {
	db *sql.DB
}

func NewDatabaseService(db *sql.DB) *DatabaseService {
	return &DatabaseService{db: db}
}

func (s *DatabaseService) GetUserByID(id int) (*models.User, error) {
	var user models.User
	err := s.db.QueryRow(
		"SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
		id,
	).Scan(
		&user.ID,
		&user.Email,
		&user.FirstName,
		&user.LastName,
		&user.Age,
		&user.CreatedAt,
	)

	if err != nil {
		log.Printf("Error getting user: %v", err)
		return nil, err
	}

	return &user, nil
}

func (s *DatabaseService) GetComplexQuery(days int) ([]models.UserStats, error) {
	// Identical to the reference implementation in src/go/fiber. The previous
	// query joined order_items and aggregated quantity*price, which is a
	// materially heavier query than the one other implementations ran, and
	// ordered only by total_value -- without a tiebreak, rows with equal
	// values come back in arbitrary order and the response is not
	// reproducible between runs. The LIMIT is part of the contract: changing
	// it changes the payload size and therefore the network ceiling.
	rows, err := s.db.Query(`
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
		log.Printf("Error in complex query: %v", err)
		return nil, err
	}
	defer rows.Close()

	var results []models.UserStats
	for rows.Next() {
		var stat models.UserStats
		err := rows.Scan(
			&stat.UserID,
			&stat.UserName,
			&stat.TotalOrders,
			&stat.TotalValue,
			&stat.AverageOrderValue,
		)
		if err != nil {
			log.Printf("Error scanning row: %v", err)
			continue
		}
		results = append(results, stat)
	}

	return results, nil
}
