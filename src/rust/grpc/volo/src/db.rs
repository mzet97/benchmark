use tokio_postgres::{Client, NoTls};

pub struct DbPool {
    pub client: Client,
}

pub async fn connect(database_url: &str) -> Result<DbPool, Box<dyn std::error::Error + Send + Sync>> {
    let (client, connection) = tokio_postgres::connect(database_url, NoTls).await?;

    tokio::spawn(async move {
        if let Err(e) = connection.await {
            eprintln!("Database connection error: {}", e);
        }
    });

    Ok(DbPool { client })
}
