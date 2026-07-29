use juniper::GraphQLObject;

#[derive(GraphQLObject)]
pub struct Health {
    pub status: String,
    pub version: String,
    pub timestamp: String,
    pub database: String,
    pub cache: String,
}

#[derive(GraphQLObject, Clone)]
pub struct JsonItem {
    pub id: i32,
    pub uuid: String,
    pub name: String,
    pub email: String,
    pub created_at: String,
    pub is_active: bool,
}

#[derive(GraphQLObject)]
pub struct JsonItemsResult {
    pub items: Vec<JsonItem>,
    pub count: i32,
    pub timestamp: String,
}

#[derive(GraphQLObject, Clone)]
pub struct User {
    pub id: i32,
    pub email: String,
    pub first_name: String,
    pub last_name: String,
    pub age: i32,
    pub created_at: String,
}

#[derive(GraphQLObject)]
pub struct UserOrderStats {
    pub user_id: i32,
    pub user_name: String,
    pub total_orders: i32,
    pub total_value: f64,
    pub average_order_value: f64,
}

#[derive(GraphQLObject)]
pub struct ComplexOrdersResult {
    pub period_days: i32,
    pub total_users: i32,
    pub data: Vec<UserOrderStats>,
}

#[derive(GraphQLObject)]
pub struct CacheEntry {
    pub key: String,
    pub value: String,
    pub cached: bool,
    pub ttl: i32,
}
