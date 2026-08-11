using Npgsql;
using MagicOnionBenchmark.Contracts;

namespace MagicOnionBenchmark.Services;

public class DatabaseService
{
    private readonly string _connectionString;

    public DatabaseService(IConfiguration configuration)
    {
        // Built from the component variables (DB_HOST/DB_PORT/DB_NAME/DB_USER/
        // DB_PASSWORD), the same way the REST siblings in src/csharp/MinimalApi
        // do, and for the same reason their comment records: the secret's
        // DATABASE_URL is a postgres:// URI carrying a percent-encoded password.
        // Npgsql accepts keyword/value connection strings only -- it does not
        // parse URI form at all -- so the DATABASE_URL fallback this constructor
        // used to rely on could not have produced a usable connection. Neither
        // does anything set ConnectionStrings__PostgreSQL: there is no
        // appsettings.json in this project and the ConfigMap does not define it.
        //
        // Maximum Pool Size comes from the contract. Npgsql pools internally, so
        // creating an NpgsqlConnection per request is correct and idiomatic -- but
        // the driver default is 100 while deploy/k3s/base/configmap.yaml fixes
        // DB_POOL_MAX=32 for every implementation. See docs/ACTION_PLAN.md,
        // Fase 9.10.2.
        var poolRaw = Environment.GetEnvironmentVariable("DB_POOL_MAX");
        if (!int.TryParse(poolRaw, out var maxPoolSize) || maxPoolSize <= 0)
        {
            maxPoolSize = 32;
        }

        var dbHost = Environment.GetEnvironmentVariable("DB_HOST");
        var dbName = Environment.GetEnvironmentVariable("DB_NAME");
        if (!string.IsNullOrEmpty(dbHost) && !string.IsNullOrEmpty(dbName))
        {
            var portRaw = Environment.GetEnvironmentVariable("DB_PORT") ?? "5432";
            _connectionString = new NpgsqlConnectionStringBuilder
            {
                Host = dbHost,
                Port = int.TryParse(portRaw, out var p) ? p : 5432,
                Database = dbName,
                Username = Environment.GetEnvironmentVariable("DB_USER"),
                Password = Environment.GetEnvironmentVariable("DB_PASSWORD"),
                Pooling = true,
                MaxPoolSize = maxPoolSize,
                MinPoolSize = maxPoolSize,
                Timeout = 30,
            }.ToString();
        }
        else
        {
            var raw = configuration.GetValue<string>("ConnectionStrings:PostgreSQL")
                ?? "Host=localhost;Port=5432;Database=benchmark;Username=benchmark;Password=benchmark";
            _connectionString = new NpgsqlConnectionStringBuilder(raw)
            {
                Pooling = true,
                MaxPoolSize = maxPoolSize,
                MinPoolSize = maxPoolSize,
            }.ToString();
        }
    }

    public async Task<UserResponse> GetUserAsync(int id)
    {
        await using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();

        await using var cmd = new NpgsqlCommand(
            "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = @id", connection);
        cmd.Parameters.AddWithValue("id", id);

        await using var reader = await cmd.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new UserResponse
            {
                Id = reader.GetInt32(0),
                Email = reader.GetString(1),
                FirstName = reader.GetString(2),
                LastName = reader.GetString(3),
                Age = reader.GetInt32(4),
                CreatedAt = reader.GetDateTime(5).ToString("o")
            };
        }

        return new UserResponse();
    }

    public async Task<ComplexOrdersResponse> GetComplexOrdersAsync(int days)
    {
        await using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();

        var sql = @"
            SELECT
                u.id AS user_id,
                u.first_name || ' ' || u.last_name AS user_name,
                COUNT(o.id) AS total_orders,
                COALESCE(SUM(o.total_amount), 0) AS total_value,
                COALESCE(AVG(o.total_amount), 0) AS average_order_value
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id AND o.created_at >= NOW() - INTERVAL '1 day' * @days
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY total_value DESC
            LIMIT 100";

        await using var cmd = new NpgsqlCommand(sql, connection);
        cmd.Parameters.AddWithValue("days", days);

        var stats = new List<UserOrderStats>();
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            stats.Add(new UserOrderStats
            {
                UserId = reader.GetInt32(0),
                UserName = reader.GetString(1),
                TotalOrders = reader.GetInt32(2),
                TotalValue = reader.GetDouble(3),
                AverageOrderValue = reader.GetDouble(4)
            });
        }

        return new ComplexOrdersResponse
        {
            PeriodDays = days,
            TotalUsers = stats.Count,
            Data = stats
        };
    }
}
