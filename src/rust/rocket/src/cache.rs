use redis::Client as RedisClient;
use anyhow::Result;
use std::io::Write;

/// Print a FATAL message to stderr (flushing so it is not lost when the
/// process aborts) and exit non-zero. See db.rs for the rationale (a panic
/// message on a startup failure can be lost before it reaches the container
/// logs, leaving CrashLoopBackOff with nothing to diagnose).
fn die(msg: impl AsRef<str>) -> ! {
    eprintln!("FATAL: {}", msg.as_ref());
    let _ = std::io::stderr().flush();
    std::process::exit(1);
}

/// Holds one MultiplexedConnection, opened at startup, and clones it per
/// command -- the clone is a cheap handle onto the same socket and the driver
/// pipelines concurrent commands from every task over it.
///
/// Every method used to call `Client::get_async_connection()`, which opens a
/// brand new TCP connection *per request*. Measured on the actix-web sibling
/// that shared this pattern, /cache ran at 1,636 rps with a 109 ms p99 against
/// 186,825 rps for the multiplexed (Lettuce) http4k implementation: the number
/// described a TCP handshake and the TIME_WAIT pileup behind it, not Redis.
#[derive(Debug)]
pub struct Cache {
    conn: redis::aio::MultiplexedConnection,
}

impl Cache {
    pub async fn new(redis_url: &str) -> Self {
        let client = RedisClient::open(redis_url)
            .unwrap_or_else(|e| die(format!("Failed to build Redis client: {e}")));

        let conn = client
            .get_multiplexed_async_connection()
            .await
            .unwrap_or_else(|e| die(format!("Failed to open multiplexed Redis connection: {e}")));

        Self { conn }
    }

    pub async fn ping(&self) -> Result<()> {
        let mut conn = self.conn.clone();
        redis::cmd("PING")
            .query_async::<_, String>(&mut conn)
            .await?;
        Ok(())
    }

    pub async fn get_or_set(&self, key: &str, value: &str, ttl_seconds: usize) -> Result<(String, String)> {
        let mut conn = self.conn.clone();

        let existing: Option<String> = redis::cmd("GET")
            .arg(key)
            .query_async(&mut conn)
            .await?;

        if let Some(existing_value) = existing {
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
