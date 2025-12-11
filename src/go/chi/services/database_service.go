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
	rows, err := s.db.Query(`
		SELECT
			u.id as user_id,
			u.first_name || ' ' || u.last_name as user_name,
			COUNT(DISTINCT o.id) as total_orders,
			COALESCE(SUM(oi.quantity * oi.price), 0) as total_value,
			COALESCE(AVG(oi.quantity * oi.price), 0) as average_value
		FROM users u
		LEFT JOIN orders o ON u.id = o.user_id
			AND o.created_at >= NOW() - INTERVAL '1 days' * $1
			AND o.status = 'completed'
		LEFT JOIN order_items oi ON o.id = oi.order_id
		WHERE o.id IS NULL OR (o.created_at >= NOW() - INTERVAL '1 days' * $1 AND o.status = 'completed')
		GROUP BY u.id, u.first_name, u.last_name
		HAVING COUNT(DISTINCT o.id) > 0
		ORDER BY total_value DESC
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
			&stat.AverageValue,
		)
		if err != nil {
			log.Printf("Error scanning row: %v", err)
			continue
		}
		results = append(results, stat)
	}

	return results, nil
}
