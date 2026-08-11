using Npgsql;

namespace GraphqlHotChocolate.Services;

public class DatabaseService
{
    private readonly string _connectionString;

    public DatabaseService(IConfiguration configuration)
    {
        var host = configuration["DB_HOST"] ?? "localhost";
        var port = configuration["DB_PORT"] ?? "5432";
        var user = configuration["DB_USER"] ?? "postgres";
        var password = configuration["DB_PASSWORD"] ?? "postgres";
        var database = configuration["DB_NAME"] ?? "benchmark";
        // Maximum Pool Size from the contract, not from the driver default.
        // Npgsql pools internally (Pooling is on by default), so creating an
        // NpgsqlConnection per request is correct and idiomatic -- but the default
        // MaxPoolSize is 100, while deploy/k3s/base/configmap.yaml fixes
        // DB_POOL_MAX=32 for every implementation precisely so the data access
        // layer stops being a hidden variable in the ranking. Three times the
        // contract's database concurrency is not a framework property.
        // See docs/ACTION_PLAN.md, Fase 9.10.2.
        var poolMax = configuration["DB_POOL_MAX"];
        if (!int.TryParse(poolMax, out var maxPoolSize) || maxPoolSize <= 0)
        {
            maxPoolSize = 32;
        }
        _connectionString =
            $"Host={host};Port={port};Username={user};Password={password};Database={database}"
            + $";Maximum Pool Size={maxPoolSize};Minimum Pool Size={maxPoolSize}";
    }

    private NpgsqlConnection CreateConnection() => new(_connectionString);

    public async Task PingAsync()
    {
        await using var conn = CreateConnection();
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand("SELECT 1", conn);
        await cmd.ExecuteNonQueryAsync();
    }

    public async Task<Types.User?> GetUserByIdAsync(int id)
    {
        await using var conn = CreateConnection();
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand(
            "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = @id",
            conn);
        cmd.Parameters.AddWithValue("@id", id);

        await using var reader = await cmd.ExecuteReaderAsync();
        if (!await reader.ReadAsync()) return null;

        return new Types.User
        {
            Id = reader.GetInt32(0),
            Email = reader.GetString(1),
            FirstName = reader.GetString(2),
            LastName = reader.GetString(3),
            Age = reader.GetInt32(4),
            CreatedAt = reader.GetDateTime(5).ToString("o")
        };
    }

    public async Task<List<Types.UserOrderStats>> GetComplexOrdersAsync(int days)
    {
        await using var conn = CreateConnection();
        await conn.OpenAsync();

        // Normative SQL, matching contracts/rest/canonical-payloads.md and the
        // REST siblings in src/csharp/{MinimalApi,Controllers,FastEndpoints}.
        // This query had drifted from the contract in five ways at once, each of
        // which on its own makes the number incomparable:
        //
        //   * no LIMIT, so it returned a row for every one of the ~10,000 seeded
        //     users instead of the 100 the contract fixes -- roughly 100x the
        //     payload and a categorically heavier query;
        //   * LEFT JOIN with the date filter folded into the ON clause, so users
        //     with no orders in the window were kept, where the contract is an
        //     INNER JOIN;
        //   * ORDER BY the summed value with no tiebreak, so rows with equal
        //     totals came back in arbitrary order and the payload was not
        //     reproducible between runs;
        //   * the average computed as SUM/COUNT through a CASE instead of AVG();
        //   * (@days || ' days')::INTERVAL, which forces the parameter to text.
        //     make_interval keeps it an integer, as the REST siblings do.
        //
        // The ::float8 casts matter for two reasons. Npgsql's GetDouble refuses a
        // numeric field outright, so reading SUM(numeric) as a double threw
        // InvalidCastException on every call -- this resolver could never have
        // returned a row. And casting in SQL avoids the extra fractional digits
        // that AVG(numeric) carries, which is what makes the REST siblings'
        // /db/complex response ~10% larger than the field median.
        await using var cmd = new NpgsqlCommand(@"
            SELECT
                u.id AS user_id,
                u.first_name || ' ' || u.last_name AS user_name,
                COUNT(o.id) AS total_orders,
                COALESCE(SUM(o.total_amount), 0)::float8 AS total_value,
                COALESCE(AVG(o.total_amount), 0)::float8 AS average_order_value
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
                WHERE o.created_at >= NOW() - make_interval(days => @days)
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY total_orders DESC, u.id
            LIMIT 100", conn);
        cmd.Parameters.AddWithValue("@days", days);

        var results = new List<Types.UserOrderStats>();
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            results.Add(new Types.UserOrderStats
            {
                UserId = reader.GetInt32(0),
                UserName = reader.GetString(1),
                // COUNT() is int8; GetInt32 on it throws InvalidCastException.
                TotalOrders = (int)reader.GetInt64(2),
                TotalValue = reader.GetDouble(3),
                AverageOrderValue = reader.GetDouble(4)
            });
        }

        return results;
    }
}
