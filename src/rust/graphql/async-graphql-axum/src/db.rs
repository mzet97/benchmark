use anyhow::Result;
use deadpool_postgres::{Config, Pool, Runtime};
use tokio_postgres::NoTls;

pub async fn create_pool() -> Result<Pool> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://benchmark:benchmark@localhost:5432/benchmark".to_string());

    let mut cfg = Config::new();
    cfg.url = Some(database_url);
    cfg.manager = Some(deadpool_postgres::ManagerConfig {
        recycling_method: deadpool_postgres::RecyclingMethod::Fast,
    });

    let pool = cfg.create_pool(Some(Runtime::Tokio1), NoTls)?;
    Ok(pool)
}

pub async fn ensure_schema(pool: &Pool) -> Result<()> {
    let conn = pool.get().await?;
    conn.execute(
        "CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            email VARCHAR(255) NOT NULL,
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100) NOT NULL,
            age INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )",
        &[],
    )
    .await?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS orders (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users(id),
            amount NUMERIC(12,2) NOT NULL,
            status VARCHAR(50) NOT NULL DEFAULT 'completed',
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )",
        &[],
    )
    .await?;

    // Seed data if empty
    let count: i64 = conn
        .query_one("SELECT COUNT(*) FROM users", &[])
        .await?
        .get(0);

    if count == 0 {
        conn.execute(
            "INSERT INTO users (email, first_name, last_name, age)
             SELECT
               'user' || i || '@example.com',
               'First' || i,
               'Last' || i,
               20 + (i % 50)
             FROM generate_series(1, 100) AS s(i)",
            &[],
        )
        .await?;

        conn.execute(
            "INSERT INTO orders (user_id, amount, status, created_at)
             SELECT
               (i % 100) + 1,
               ROUND((random() * 500 + 10)::numeric, 2),
               CASE WHEN random() > 0.1 THEN 'completed' ELSE 'pending' END,
               NOW() - (random() * interval '90 days')
             FROM generate_series(1, 1000) AS s(i)",
            &[],
        )
        .await?;
    }

    Ok(())
}
