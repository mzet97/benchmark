use redis::Client as RedisClient;
use anyhow::Result;
use std::io::Write;

/// Print a FATAL message to stderr (flushing so it is not lost when the
/// process aborts) and exit non-zero. See db.rs for the rationale (the
/// release profile uses `panic = "abort"` + `strip = true`, which can lose
/// the panic message before it reaches the container logs).
fn die(msg: impl AsRef<str>) -> ! {
    eprintln!("FATAL: {}", msg.as_ref());
    let _ = std::io::stderr().flush();
    std::process::exit(1);
}

#[derive(Debug)]
pub struct Cache {
    client: RedisClient,
}

impl Cache {
    pub async fn new(redis_url: &str) -> Self {
        let client = RedisClient::open(redis_url)
            .unwrap_or_else(|e| die(format!("Failed to build Redis client: {e}")));

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
