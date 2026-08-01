using BenchmarkFastEndpoints.Services;
using FastEndpoints;

namespace BenchmarkFastEndpoints.Endpoints;

public class ComplexDbRequest
{
    public int? Days { get; set; }
}

public class ComplexDbEndpoint : Endpoint<ComplexDbRequest>
{
    private readonly IDatabaseService _databaseService;
    private readonly ILogger<ComplexDbEndpoint> _logger;

    public ComplexDbEndpoint(IDatabaseService databaseService, ILogger<ComplexDbEndpoint> logger)
    {
        _databaseService = databaseService;
        _logger = logger;
    }

    public override void Configure()
    {
        Get("/db/complex");
        AllowAnonymous();
    }

    public override async Task HandleAsync(ComplexDbRequest req, CancellationToken ct)
    {
        var queryDays = req.Days ?? 30;

        if (queryDays <= 0 || queryDays > 365)
        {
            await SendAsync(new { error = "Days must be between 1 and 365" }, 400, cancellation: ct);
            return;
        }

        _logger.LogInformation("Complex DB query requested for last {Days} days", queryDays);
        var results = await _databaseService.GetComplexQueryAsync(queryDays);

        await SendAsync(new
        {
            periodDays = queryDays,
            totalUsers = results.Length,
            data = results
        }, cancellation: ct);
    }
}
