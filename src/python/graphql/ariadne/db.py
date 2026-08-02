import os
import psycopg2
import psycopg2.pool

_pool = None


def get_pool():
    global _pool
    if _pool is None:
        database_url = os.environ.get(
            "DATABASE_URL",
            "postgres://benchmark:benchmark@localhost:5432/benchmark",
        )
        _pool = psycopg2.pool.ThreadedConnectionPool(1, 10, database_url)
    return _pool


def get_connection():
    return get_pool().getconn()


def put_connection(conn):
    get_pool().putconn(conn)


def check_db():
    """Returns 'connected' or 'disconnected'."""
    try:
        conn = get_connection()
        try:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
            return "connected"
        finally:
            put_connection(conn)
    except Exception:
        return "disconnected"


def ensure_schema():
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                email VARCHAR(255) NOT NULL,
                first_name VARCHAR(100) NOT NULL,
                last_name VARCHAR(100) NOT NULL,
                age INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL DEFAULT NOW()
            )
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS orders (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id),
                amount NUMERIC(12,2) NOT NULL,
                status VARCHAR(50) NOT NULL DEFAULT 'completed',
                created_at TIMESTAMP NOT NULL DEFAULT NOW()
            )
        """)
        conn.commit()

        cur.execute("SELECT COUNT(*) FROM users")
        count = cur.fetchone()[0]
        if count == 0:
            cur.execute("""
                INSERT INTO users (email, first_name, last_name, age)
                SELECT
                    'user' || i || '@example.com',
                    'First' || i,
                    'Last' || i,
                    20 + (i % 50)
                FROM generate_series(1, 100) AS s(i)
            """)
            cur.execute("""
                INSERT INTO orders (user_id, amount, status, created_at)
                SELECT
                    (i % 100) + 1,
                    ROUND((random() * 500 + 10)::numeric, 2),
                    CASE WHEN random() > 0.1 THEN 'completed' ELSE 'pending' END,
                    NOW() - (random() * interval '90 days')
                FROM generate_series(1, 1000) AS s(i)
            """)
            conn.commit()
        cur.close()
    finally:
        put_connection(conn)


def get_user(user_id: int):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = %s",
            (user_id,),
        )
        row = cur.fetchone()
        cur.close()
        if row is None:
            return None
        return {
            "id": row[0],
            "email": row[1],
            "firstName": row[2],
            "lastName": row[3],
            "age": row[4],
            "createdAt": row[5].isoformat(),
        }
    finally:
        put_connection(conn)


def get_complex_orders(days: int = 30):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            -- Normative SQL, see contracts/rest/canonical-payloads.md. The
            -- previous query aggregated o.total or o.amount, columns the schema
            -- does not have; the interval was pasted in as text rather than
            -- bound, so it was never substituted; the ORDER BY had no tiebreak;
            -- and there was no LIMIT, so it returned every user rather than the
            -- 100 the contract fixes -- which changes the payload size and the
            -- network ceiling of this scenario.
            SELECT
                u.id AS user_id,
                u.first_name || ' ' || u.last_name AS user_name,
                COUNT(o.id) AS total_orders,
                COALESCE(SUM(o.total_amount), 0) AS total_value,
                COALESCE(AVG(o.total_amount), 0) AS average_order_value
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
                WHERE o.created_at >= NOW() - INTERVAL '1 day' * %s
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY total_orders DESC, u.id
            LIMIT 100
            """,
            (days,),
        )
        rows = cur.fetchall()
        cur.close()
        return [
            {
                "userId": r[0],
                "userName": r[1],
                "totalOrders": r[2],
                "totalValue": float(r[3]),
                "averageOrderValue": float(r[4]),
            }
            for r in rows
        ]
    finally:
        put_connection(conn)
