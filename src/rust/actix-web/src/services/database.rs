use bb8::Pool;
use bb8_postgres::PostgresConnectionManager;
use chrono::Utc;
use log::info;
use tokio_postgres::{Client, Row};
use uuid::Uuid;

use crate::models::{User, Order, OrderItem, ComplexOrderResult};

pub struct DatabaseService {
    pool: Pool<PostgresConnectionManager>,
}

impl DatabaseService {
    pub fn new(pool: Pool<PostgresConnectionManager>) -> Self {
        Self { pool }
    }

    pub async fn get_user_by_id(&self, id: i32) -> Result<Option<User>, Box<dyn std::error::Error>> {
        let conn = self.pool.get().await?;

        let query = "
            SELECT id, email, first_name, last_name, created_at
            FROM users
            WHERE id = $1
        ";

        let row = conn.query_opt(query, &[&id]).await?;

        match row {
            Some(row) => {
                let user = User {
                    id: row.get("id"),
                    email: row.get("email"),
                    first_name: row.get("first_name"),
                    last_name: row.get("last_name"),
                    created_at: row.get("created_at"),
                };
                Ok(Some(user))
            }
            None => Ok(None),
        }
    }

    pub async fn get_complex_orders(
        &self,
        days: i32,
    ) -> Result<Vec<ComplexOrderResult>, Box<dyn std::error::Error>> {
        let conn = self.pool.get().await?;

        let query = "
            SELECT
                u.id as user_id,
                u.email,
                COUNT(o.id) as order_count,
                SUM(o.total_amount) as total_amount,
                AVG(o.total_amount) as avg_amount,
                EXTRACT(DAY FROM (NOW() - MIN(o.created_at))) as days_since_first_order
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
            WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
            GROUP BY u.id, u.email
            ORDER BY order_count DESC
            LIMIT 100
        ";

        let rows = conn.query(query, &[&days]).await?;

        let mut results = Vec::new();
        for row in rows {
            let result = ComplexOrderResult {
                user_id: row.get("user_id"),
                email: row.get("email"),
                order_count: row.get("order_count"),
                total_amount: row.get("total_amount"),
                avg_amount: row.get("avg_amount"),
                days_since_first_order: row.get("days_since_first_order"),
            };
            results.push(result);
        }

        Ok(results)
    }

    pub async fn health_check(&self) -> Result<bool, Box<dyn std::error::Error>> {
        let conn = self.pool.get().await?;
        let result = conn.query_opt("SELECT 1", &[]).await?;
        Ok(result.is_some())
    }
}
