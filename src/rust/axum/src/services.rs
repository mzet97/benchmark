use sqlx::{PgPool, Row};
use redis::Client as RedisClient;
use anyhow::{Result, Context};
use std::env;
use serde::Serialize;

#[derive(Debug, Clone)]
pub struct DatabaseService {
    pool: PgPool,
}

impl DatabaseService {
    pub async fn new() -> Self {
        let database_url = env::var("DATABASE_URL")
            .unwrap_or_else(|_| "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api".to_string());

        let pool = PgPool::connect(&database_url)
            .await
            .expect("Failed to connect to database");

        Self { pool }
    }

    pub async fn health_check(&self) -> Result<()> {
        sqlx::query("SELECT 1")
            .fetch_one(&self.pool)
            .await
            .map(|_| ())
            .context("Database health check failed")
    }

    pub async fn get_user(&self, id: i32) -> Result<Option<User>> {
        let user = sqlx::query_as!(
            User,
            "SELECT id, email, first_name, last_name, age, created_at 
             FROM users WHERE id = $1",
            id
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn get_complex_query(&self, days: i32) -> Result<Vec<ComplexUserStats>> {
        let users = sqlx::query!(
            r#"
            SELECT u.id as user_id,
                   u.email as user_email,
                   COUNT(DISTINCT o.id) as total_orders,
                   COALESCE(SUM(o.total_amount), 0) as total_value,
                   COALESCE(AVG(o.total_amount), 0) as average_value,
                   EXTRACT(DAY FROM NOW() - MIN(o.created_at)) as days_since_first_order
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id
              AND o.created_at >= NOW() - INTERVAL '%s days'
            GROUP BY u.id, u.email
            HAVING COUNT(DISTINCT o.id) > 0
            ORDER BY total_value DESC
            LIMIT 100
            "#,
            days
        )
        .fetch_all(&self.pool)
        .await?;

        let result: Vec<ComplexUserStats> = users
            .into_iter()
            .map(|row| ComplexUserStats {
                user_id: row.user_id,
                user_email: row.user_email,
                total_orders: row.total_orders,
                total_value: row.total_value,
                average_value: row.average_value,
                days_since_first_order: row.days_since_first_order,
            })
            .collect();

        Ok(result)
    }
}

#[derive(Debug, Clone)]
pub struct CacheService {
    client: RedisClient,
}

impl CacheService {
    pub async fn new() -> Self {
        let redis_url = env::var("REDIS_URL")
            .unwrap_or_else(|_| "redis://:Admin@123@redis.home.arpa:30379".to_string());

        let client = RedisClient::open(redis_url)
            .expect("Failed to connect to Redis");

        Self { client }
    }

    pub async fn ping(&self) -> Result<()> {
        let mut conn = self.client.get_async_connection().await?;
        redis::cmd("PING")
            .query_async::<_, String>(&mut conn)
            .await?;
        Ok(())
    }

    pub async fn get_or_set(&self, key: &str, value: &str, ttl_seconds: usize) -> Result<(String, String)> {
        let mut conn = self.client.get_async_connection().await?;

        if let Some(existing_value): Option<String> = redis::cmd("GET")
            .arg(key)
            .query_async(&mut conn)
            .await?
        {
            Ok((existing_value, "cache".to_string()))
        } else {
            redis::cmd("SETEX")
                .arg(key)
                .arg(ttl_seconds)
                .arg(value)
                .query_async::<_, String>(&mut conn)
                .await?;
            Ok((value.to_string(), "generated".to_string()))
        }
    }
}

#[derive(sqlx::FromRow, Debug, Clone, Serialize)]
pub struct User {
    pub id: i32,
    pub email: String,
    pub first_name: String,
    pub last_name: String,
    pub age: Option<i32>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct ComplexUserStats {
    pub user_id: i32,
    pub user_email: String,
    pub total_orders: i64,
    pub total_value: f64,
    pub average_value: f64,
    pub days_since_first_order: f64,
}
