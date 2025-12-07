-- Additional indexes for benchmark queries optimization

-- Indexes for simple query: SELECT * FROM users WHERE id = ?
-- The primary key index is already sufficient (id SERIAL PRIMARY KEY)

-- Indexes for complex query optimization
-- Query: JOIN users, orders, order_items with aggregation and date filter
-- WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'

-- This index helps with the date filter on orders
CREATE INDEX IF NOT EXISTS idx_orders_created_at_desc ON orders(created_at DESC);

-- This index helps with aggregation by user_id
CREATE INDEX IF NOT EXISTS idx_orders_user_id_created_at ON orders(user_id, created_at);

-- This index helps with the JOIN between orders and order_items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id_created_at ON order_items(order_id, created_at);

-- Partial index for active orders (status = 'completed')
CREATE INDEX IF NOT EXISTS idx_orders_completed_user ON orders(user_id) WHERE status = 'completed';

-- Analyze tables after adding indexes
ANALYZE users;
ANALYZE orders;
ANALYZE order_items;

-- Show index usage statistics
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('users', 'orders', 'order_items')
ORDER BY tablename, indexname;
