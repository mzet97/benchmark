use deadpool_postgres::{Manager, ManagerConfig, Pool, RecyclingMethod};
use tokio_postgres::{NoTls, Row};

pub type DbError = Box<dyn std::error::Error + Send + Sync>;

/// Pool size is part of the benchmark contract, not a per-implementation
/// choice: every implementation reads DB_POOL_MAX from the same ConfigMap so
/// the data access layer stops being a hidden variable in the ranking.
fn db_pool_max() -> usize {
    std::env::var("DB_POOL_MAX")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .filter(|n| *n > 0)
        .unwrap_or(32)
}

/// Normative SQL, see contracts/rest/canonical-payloads.md. Kept here so the
/// three Rust gRPC implementations cannot drift from it independently -- which
/// is exactly what had happened: each carried its own copy, and between them
/// they aggregated `o.total` (a column that does not exist), returned NUMERIC
/// where the response field is a double, joined with LEFT JOIN instead of
/// INNER JOIN, and ordered without a tiebreak.
const COMPLEX_SQL: &str = "SELECT
        u.id AS user_id,
        u.first_name || ' ' || u.last_name AS user_name,
        COUNT(o.id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0)::float8 AS total_value,
        COALESCE(AVG(o.total_amount), 0)::float8 AS average_order_value
     FROM users u
     INNER JOIN orders o ON u.id = o.user_id
        WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
     GROUP BY u.id, u.first_name, u.last_name
     ORDER BY total_orders DESC, u.id
     LIMIT 100";

const USER_SQL: &str =
    "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1";

/// A pool, not a single connection.
///
/// This used to hold one bare `tokio_postgres::Client`. tokio-postgres does
/// pipeline concurrent queries over a single socket, so it did not deadlock --
/// but a single connection is a single PostgreSQL backend process, which
/// executes those queries one after another. Every other implementation in the
/// matrix ran DB_POOL_MAX=32 connections, so this measured 1/32 of the
/// contract's database concurrency and ignored the ConfigMap knob whose entire
/// purpose is to stop the data access layer from being a hidden variable.
pub struct DbPool {
    pool: Pool,
}

impl Clone for DbPool {
    fn clone(&self) -> Self {
        // Pool is a handle; cloning shares the same connections.
        DbPool { pool: self.pool.clone() }
    }
}

pub async fn connect(database_url: &str) -> Result<DbPool, DbError> {
    let config = database_url.parse::<tokio_postgres::Config>()?;
    let manager = Manager::from_config(
        config,
        NoTls,
        ManagerConfig { recycling_method: RecyclingMethod::Fast },
    );
    let pool = Pool::builder(manager).max_size(db_pool_max()).build()?;

    // Fail at startup rather than on the first request if the credentials or
    // the host are wrong.
    let _ = pool.get().await?;

    Ok(DbPool { pool })
}

impl DbPool {
    pub async fn health_check(&self) -> Result<(), DbError> {
        let client = self.pool.get().await?;
        let stmt = client.prepare_cached("SELECT 1").await?;
        client.query_one(&stmt, &[]).await?;
        Ok(())
    }

    /// prepare_cached, not query_one(&str): tokio_postgres::Client::query*
    /// called with a &str runs Parse+Describe on every call, so each request
    /// paid two round-trips to Postgres where every pooled implementation pays
    /// one.
    pub async fn query_user(&self, id: i32) -> Result<Row, DbError> {
        let client = self.pool.get().await?;
        let stmt = client.prepare_cached(USER_SQL).await?;
        Ok(client.query_one(&stmt, &[&id]).await?)
    }

    pub async fn query_complex(&self, days: i32) -> Result<Vec<Row>, DbError> {
        let client = self.pool.get().await?;
        let stmt = client.prepare_cached(COMPLEX_SQL).await?;
        // $1 is bound as f64, not i32. The previous SQL wrote
        // `($1 || ' days')::interval`, which makes Postgres infer $1 as text,
        // and `impl ToSql for i32` only accepts INT4 -- so the bind was
        // rejected before the query ran. With the normative
        // `INTERVAL '1 day' * $1` the inferred type is float8, for the same
        // reason: Postgres has no `interval * int4` operator.
        Ok(client.query(&stmt, &[&f64::from(days)]).await?)
    }
}
