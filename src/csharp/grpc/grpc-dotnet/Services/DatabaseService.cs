using Npgsql;
using Benchmark;

namespace GrpcDotnet.Services;

public class DatabaseService
{
    private readonly string _connectionString;

    public DatabaseService(IConfiguration configuration)
    {
        _connectionString = configuration.GetValue<string>("ConnectionStrings:PostgreSQL")
            ?? Environment.GetEnvironmentVariable("DATABASE_URL")
            ?? "Host=localhost;Port=5432;Database=benchmark;Username=benchmark;Password=benchmark";
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
            Data = { stats }
        };
    }
}
