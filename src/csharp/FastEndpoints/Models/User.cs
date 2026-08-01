namespace BenchmarkFastEndpoints.Models;

// Mirrors UserResponse in contracts/grpc/benchmark.proto. ASP.NET Core's web
// defaults serialize these as camelCase, which is what the contract asks for.
// See contracts/rest/canonical-payloads.md.
public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    // Nullable in the schema; reading it with GetInt32 threw on any row with
    // no age.
    public int? Age { get; set; }
    public DateTime CreatedAt { get; set; }
}
