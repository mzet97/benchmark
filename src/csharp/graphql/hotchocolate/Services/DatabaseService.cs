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
        _connectionString =
            $"Host={host};Port={port};Username={user};Password={password};Database={database}";
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

        await using var cmd = new NpgsqlCommand(@"
            SELECT
                u.id,
                u.first_name || ' ' || u.last_name,
                COUNT(o.id),
                COALESCE(SUM(o.total_amount), 0),
                CASE WHEN COUNT(o.id) > 0
                    THEN COALESCE(SUM(o.total_amount), 0) / COUNT(o.id)
                    ELSE 0
                END
            FROM users u
            LEFT JOIN orders o ON o.user_id = u.id
                AND o.created_at >= NOW() - (@days || ' days')::INTERVAL
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY COALESCE(SUM(o.total_amount), 0) DESC", conn);
        cmd.Parameters.AddWithValue("@days", days.ToString());

        var results = new List<Types.UserOrderStats>();
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            results.Add(new Types.UserOrderStats
            {
                UserId = reader.GetInt32(0),
                UserName = reader.GetString(1),
                TotalOrders = reader.GetInt32(2),
                TotalValue = reader.GetDouble(3),
                AverageOrderValue = reader.GetDouble(4)
            });
        }

        return results;
    }
}
