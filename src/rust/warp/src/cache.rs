use redis::Client as RedisClient;
use anyhow::Result;
use serde::Deserialize;

#[derive(Debug)]
pub struct Cache {
    client: RedisClient,
}

impl Cache {
    pub async fn new(redis_url: &str) -> Self {
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

        let existing_value: Option<String> = redis::cmd("GET")
            .arg(key)
            .query_async(&mut conn)
            .await?;

        if let Some(val) = existing_value {
            Ok((val, "cache".to_string()))
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

#[derive(Debug, Deserialize)]
pub struct CacheQuery {
    pub key: Option<String>,
}
