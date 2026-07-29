use redis::aio::MultiplexedConnection;

#[derive(Clone)]
pub struct CacheClient {
    pub conn: MultiplexedConnection,
}

pub async fn connect(redis_url: &str) -> Result<CacheClient, Box<dyn std::error::Error>> {
    let client = redis::Client::open(redis_url)?;
    let conn = client.get_multiplexed_async_connection().await?;
    Ok(CacheClient { conn })
}
