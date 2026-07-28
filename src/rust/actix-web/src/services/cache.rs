use redis::Client as RedisClient;
use log::info;

pub struct CacheService {
    client: RedisClient,
}

impl CacheService {
    pub fn new(client: RedisClient) -> Self {
        Self { client }
    }

    pub async fn get(&self, key: &str) -> Result<Option<String>, Box<dyn std::error::Error>> {
        let mut conn = self.client.get_multiplexed_async_connection().await?;
        let result: Option<String> = redis::cmd("GET").arg(key).query_async(&mut conn).await?;
        if result.is_some() {
            info!("Cache hit for key: {}", key);
        }
        Ok(result)
    }

    pub async fn set(
        &self,
        key: &str,
        value: &str,
        ttl_seconds: i32,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut conn = self.client.get_multiplexed_async_connection().await?;
        let _: () = redis::cmd("SETEX").arg(key).arg(ttl_seconds).arg(value).query_async(&mut conn).await?;
        Ok(())
    }

    pub async fn health_check(&self) -> Result<bool, Box<dyn std::error::Error>> {
        let mut conn = self.client.get_multiplexed_async_connection().await?;
        let _: () = redis::cmd("PING").query_async(&mut conn).await?;
        Ok(true)
    }
}
