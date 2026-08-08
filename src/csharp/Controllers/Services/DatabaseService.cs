using BenchmarkControllers.Models;
using Npgsql;

namespace BenchmarkControllers.Services;

public interface IDatabaseService
{
    Task<User?> GetUserByIdAsync(int id);
    Task<ComplexResult[]> GetComplexQueryAsync(int days);
}

public class DatabaseService : IDatabaseService
{
    private readonly string _connectionString;

    public DatabaseService(IConfiguration configuration)
    {
        // Prefer the connection string Program.cs already built from the
        // component ConfigMap/Secret variables (DB_HOST/DB_PORT/DB_NAME/
        // DB_USER/DB_PASSWORD). The previous code read DATABASE_URL first and
        // hand-parsed it without percent-decoding the userinfo, so the literal
        // "Admin%40123" reached Postgres and every query failed auth.
        var configured = configuration.GetConnectionString("DefaultConnection");
        if (!string.IsNullOrEmpty(configured))
        {
            _connectionString = configured;
            return;
        }

        var url = Environment.GetEnvironmentVariable("DATABASE_URL")
            ?? throw new InvalidOperationException("Database connection string not found");

        // Npgsql's own builder parses the URL and percent-decodes the password
        // (the hand-rolled split() here did not, which broke auth for the
        // encoded @ in the password).
        if (url.StartsWith("postgresql://") || url.StartsWith("postgres://"))
        {
            var builder = new NpgsqlConnectionStringBuilder(url)
            {
                Pooling = true,
                MaxPoolSize = int.Parse(Environment.GetEnvironmentVariable("DB_POOL_MAX") ?? "32"),
                Timeout = 30,
            };
            _connectionString = builder.ToString();
        }
        else
        {
            _connectionString = url;
        }
    }

    public async Task<User?> GetUserByIdAsync(int id)
    {
        using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();

        using var cmd = new NpgsqlCommand(
            "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = @Id",
            connection);
        cmd.Parameters.AddWithValue("Id", id);

        using var reader = await cmd.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new User
            {
                Id = reader.GetInt32(0),
                Email = reader.GetString(1),
                FirstName = reader.GetString(2),
                LastName = reader.GetString(3),
                Age = reader.IsDBNull(4) ? null : reader.GetInt32(4),
                CreatedAt = reader.GetDateTime(5)
            };
        }

        return null;
    }

    public async Task<ComplexResult[]> GetComplexQueryAsync(int days)
    {
        using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();

        var results = new List<ComplexResult>();

        // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
        // query joined order_items and aggregated quantity*price -- a
        // materially heavier query than the one other implementations ran --
        // and ordered only by TotalValue, so rows with equal values came back
        // in arbitrary order and the response was not reproducible.
        using var cmd = new NpgsqlCommand(@"
            SELECT
                u.id AS UserId,
                u.first_name || ' ' || u.last_name AS UserName,
                COUNT(o.id) AS TotalOrders,
                COALESCE(SUM(o.total_amount), 0) AS TotalValue,
                COALESCE(AVG(o.total_amount), 0) AS AverageOrderValue
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
                WHERE o.created_at >= NOW() - make_interval(days => @Days)
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY TotalOrders DESC, u.id
            LIMIT 100", connection);

        cmd.Parameters.AddWithValue("Days", days);

        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            results.Add(new ComplexResult
            {
                UserId = reader.GetInt32(0),
                UserName = reader.GetString(1),
                TotalOrders = reader.GetInt64(2),
                TotalValue = reader.GetDecimal(3),
                AverageOrderValue = reader.GetDecimal(4)
            });
        }

        return results.ToArray();
    }
}
