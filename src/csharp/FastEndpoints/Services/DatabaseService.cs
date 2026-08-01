using BenchmarkFastEndpoints.Models;
using Npgsql;

namespace BenchmarkFastEndpoints.Services;

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
        var url = Environment.GetEnvironmentVariable("DATABASE_URL")
            ?? configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Database connection string not found");

        // Parse postgresql://user:password@host:port/database
        // Handle @ in password by splitting from last @
        if (url.StartsWith("postgresql://"))
        {
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
