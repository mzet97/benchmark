using Npgsql;

namespace BenchmarkApi.Services;

public interface IDatabaseService
{
    Task<User?> GetUserByIdAsync(int id);
    Task<ComplexQueryResult[]> GetComplexQueryAsync(int days);
}

public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public int Age { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ComplexQueryResult
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public int TotalOrders { get; set; }
    public decimal TotalValue { get; set; }
    public decimal AverageOrderValue { get; set; }
}

public class DatabaseService : IDatabaseService
{
    private readonly string _connectionString;

    public DatabaseService(IConfiguration configuration)
    {
        var url = configuration.GetConnectionString("DefaultConnection")
            ?? Environment.GetEnvironmentVariable("DATABASE_URL")
            ?? throw new InvalidOperationException("Database connection string not found");

        // Parse postgresql://user:password@host:port/database
        // Handle @ in password by splitting from last @
        var lastAt = url.LastIndexOf('@');
        var schemeEnd = url.IndexOf("://");
        var userPass = url.Substring(schemeEnd + 3, lastAt - schemeEnd - 3);
        var hostPortDb = url.Substring(lastAt + 1);
        var user = userPass.Split(':')[0];
        var password = userPass.Contains(':') ? userPass.Substring(userPass.IndexOf(':') + 1) : "";
        var host = hostPortDb.Split(':')[0];
        var portDb = hostPortDb.Substring(hostPortDb.IndexOf(':') + 1);
        var port = portDb.Split('/')[0];
        var database = portDb.Contains('/') ? portDb.Substring(portDb.IndexOf('/') + 1) : "";

        _connectionString = $"Host={host};Port={port};Database={database};Username={user};Password={password};Maximum Pool Size=25;Connection Timeout=30";
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
                Age = reader.GetInt32(4),
                CreatedAt = reader.GetDateTime(5)
            };
        }

        return null;
    }

    public async Task<ComplexQueryResult[]> GetComplexQueryAsync(int days)
    {
        using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();

        var results = new List<ComplexQueryResult>();

        using var cmd = new NpgsqlCommand(@"
            SELECT
                u.id as UserId,
                u.first_name || ' ' || u.last_name as UserName,
                COUNT(DISTINCT o.id) as TotalOrders,
                COALESCE(SUM(oi.quantity * oi.price), 0) as TotalValue,
                COALESCE(AVG(oi.quantity * oi.price), 0) as AverageOrderValue
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id
                AND o.created_at >= CURRENT_DATE - make_interval(days => @Days)
                AND o.status = 'completed'
            LEFT JOIN order_items oi ON o.id = oi.order_id
            WHERE o.id IS NULL OR (o.created_at >= CURRENT_DATE - make_interval(days => @Days) AND o.status = 'completed')
            GROUP BY u.id, u.first_name, u.last_name
            HAVING COUNT(DISTINCT o.id) > 0
            ORDER BY TotalValue DESC
            LIMIT 100", connection);

        cmd.Parameters.AddWithValue("Days", days);

        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            results.Add(new ComplexQueryResult
            {
                UserId = reader.GetInt32(0),
                UserName = reader.GetString(1),
                TotalOrders = reader.GetInt32(2),
                TotalValue = reader.GetDecimal(3),
                AverageOrderValue = reader.GetDecimal(4)
            });
        }

        return results.ToArray();
    }
}
