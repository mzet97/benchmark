use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct User {
    pub id: i32,
    pub email: String,
    pub first_name: String,
    pub last_name: String,
    pub created_at: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OrderItem {
    pub id: i32,
    pub order_id: i32,
    pub product_name: String,
    pub quantity: i32,
    pub unit_price: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Order {
    pub id: i32,
    pub user_id: i32,
    pub total_amount: f64,
    pub status: String,
    pub created_at: String,
    pub items: Vec<OrderItem>,
    pub user: Option<User>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ComplexOrderResult {
    pub user_id: i32,
    pub email: String,
    pub order_count: i64,
    pub total_amount: f64,
    pub avg_amount: f64,
    pub days_since_first_order: i64,
}
