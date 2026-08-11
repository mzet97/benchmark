use anyhow::Result;
use deadpool_postgres::{Config, Pool, Runtime};
use tokio_postgres::NoTls;

/// Pool size is part of the benchmark contract, not a per-implementation
/// choice: every implementation reads DB_POOL_MAX from the same ConfigMap so
/// the data access layer stops being a hidden variable in the ranking.
///
/// This pool previously left max_size unset, which means deadpool's default of
/// `cpu_count * 4` -- 160 connections in the 40-CPU benchmark pod, five times
/// the contract's 32, against a PostgreSQL ceiling measured in Fase 0.
fn db_pool_max() -> usize {
    std::env::var("DB_POOL_MAX")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .filter(|n| *n > 0)
        .unwrap_or(32)
}

pub async fn create_pool() -> Result<Pool> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://benchmark:benchmark@localhost:5432/benchmark".to_string());

    let mut cfg = Config::new();
    cfg.url = Some(database_url);
    cfg.manager = Some(deadpool_postgres::ManagerConfig {
        recycling_method: deadpool_postgres::RecyclingMethod::Fast,
    });
    cfg.pool = Some(deadpool_postgres::PoolConfig {
        max_size: db_pool_max(),
        ..Default::default()
    });

    let pool = cfg.create_pool(Some(Runtime::Tokio1), NoTls)?;
    Ok(pool)
}

// ensure_schema() used to live here and ran at every startup. It has been
// removed rather than fixed.
//
// The benchmark database is provisioned once by sql/01_schema.sql via
// scripts/setup-database.sh: 10k users, 50k orders, 200k order_items. The
// startup routine instead issued CREATE TABLE IF NOT EXISTS with a *different*
// schema -- `orders.amount` where the real column is `orders.total_amount` --
// and, when it found the users table empty, seeded 100 users and 1000 orders.
//
// Against the real database the IF NOT EXISTS made it a no-op, so it was dead
// weight on the startup path. Against an empty one it produced a schema whose
// column names this crate's own queries do not use, plus a dataset 100x smaller
// than every other implementation measures against -- a silently
// unrepresentative benchmark instead of a loud failure. Provisioning belongs to
// setup-database.sh; the application should read the contract's data or fail.
