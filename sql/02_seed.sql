-- Seed data for Benchmark API
-- 10,000 users, 50,000 orders, 200,000 order_items

-- Enable timing for monitoring
\timing on

-- Seed 10,000 users
INSERT INTO users (email, first_name, last_name, age)
SELECT
    'user' || generate_series || '@example.com',
    CASE (generate_series % 50)
        WHEN 0 THEN 'John'
        WHEN 1 THEN 'Jane'
        WHEN 2 THEN 'Bob'
        WHEN 3 THEN 'Alice'
        WHEN 4 THEN 'Charlie'
        WHEN 5 THEN 'Diana'
        WHEN 6 THEN 'Eve'
        WHEN 7 THEN 'Frank'
        WHEN 8 THEN 'Grace'
        WHEN 9 THEN 'Henry'
        ELSE 'User' || generate_series
    END,
    CASE (generate_series % 50)
        WHEN 0 THEN 'Smith'
        WHEN 1 THEN 'Johnson'
        WHEN 2 THEN 'Williams'
        WHEN 3 THEN 'Brown'
        WHEN 4 THEN 'Jones'
        WHEN 5 THEN 'Garcia'
        WHEN 6 THEN 'Miller'
        WHEN 7 THEN 'Davis'
        WHEN 8 THEN 'Rodriguez'
        WHEN 9 THEN 'Martinez'
        ELSE 'LastName' || generate_series
    END,
    (random() * 50 + 18)::INTEGER
FROM generate_series(1, 10000);

-- Seed 50,000 orders
INSERT INTO orders (user_id, total_amount, status, created_at)
SELECT
    (random() * 9999 + 1)::INTEGER,
    (random() * 1000 + 10)::DECIMAL(10,2),
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'completed'
        WHEN 2 THEN 'cancelled'
        ELSE 'processing'
    END,
    CURRENT_TIMESTAMP - (random() * INTERVAL '365 days')
FROM generate_series(1, 50000);

-- Seed 200,000 order items (average 4 items per order)
INSERT INTO order_items (order_id, product_name, quantity, price)
SELECT
    (random() * 49999 + 1)::INTEGER,
    'Product ' || (random() * 999)::INTEGER,
    (random() * 5 + 1)::INTEGER,
    (random() * 100 + 1)::DECIMAL(10,2)
FROM generate_series(1, 200000);

-- Update statistics for query optimization
ANALYZE users;
ANALYZE orders;
ANALYZE order_items;

-- Verify data
SELECT 'users' as table_name, COUNT(*) as row_count FROM users
UNION ALL
SELECT 'orders' as table_name, COUNT(*) as row_count FROM orders
UNION ALL
SELECT 'order_items' as table_name, COUNT(*) as row_count FROM order_items;

-- Show sample data
SELECT * FROM users LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items LIMIT 5;
