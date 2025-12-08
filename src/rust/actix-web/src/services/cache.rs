use redis::Client as RedisClient;
use redis::Commands;
use log::info;

pub struct CacheService {
    client: RedisClient,
}

impl CacheService {
    pub fn new(client: RedisClient) -> Self {
        Self { client }
    }

    pub async fn get(&self, key: &str) -> Result<Option<String>, Box<dyn std::error::Error>> {
        let mut conn = self.client.get_async_connection().await?;

        let result: Option<String> = conn.get(key).await?;

        match result {
            Some(value) => {
                info!("Cache hit for key: {}", key);
                Ok(Some(value))
            }
            None => {
                info!("Cache miss for key: {}", key);
                Ok(None)
            }
        }
    }

    pub async fn set(
        &self,
        key: &str,
        value: &str,
        ttl_seconds: i32,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut conn = self.client.get_async_connection().await?;
        conn.set_ex(key, value, ttl_seconds as usize).await?;
        Ok(())
    }

    pub async fn health_check(&self) -> Result<bool, Box<dyn std::error::Error>> {
        let mut conn = self.client.get_async_connection().await?;
        let _: String = redis::cmd("PING")
            .query_async(&mut conn)
            .await?;
        Ok(true)
    }
}
