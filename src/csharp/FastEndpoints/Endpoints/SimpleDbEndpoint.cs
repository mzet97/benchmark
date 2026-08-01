using BenchmarkFastEndpoints.Services;
using FastEndpoints;

namespace BenchmarkFastEndpoints.Endpoints;

public class SimpleDbRequest
{
    public int? Id { get; set; }
}

public class SimpleDbEndpoint : Endpoint<SimpleDbRequest>
{
    private readonly IDatabaseService _databaseService;
    private readonly ILogger<SimpleDbEndpoint> _logger;

    public SimpleDbEndpoint(IDatabaseService databaseService, ILogger<SimpleDbEndpoint> logger)
    {
        _databaseService = databaseService;
        _logger = logger;
    }

    public override void Configure()
    {
        Get("/db/simple");
        AllowAnonymous();
    }

    public override async Task HandleAsync(SimpleDbRequest req, CancellationToken ct)
    {
        if (!req.Id.HasValue || req.Id <= 0)
        {
            await SendAsync(new { error = "Invalid id parameter" }, 400, cancellation: ct);
            return;
        }

        _logger.LogInformation("Simple DB query requested for id: {Id}", req.Id);
        var user = await _databaseService.GetUserByIdAsync(req.Id.Value);

        if (user == null)
        {
            await SendAsync(new { error = $"User with id {req.Id} not found" }, 404, cancellation: ct);
            return;
        }

        // The contract returns the user object itself. The previous DTO was
        // {Id, Name, Email, CreatedAt, IsActive}: first and last name
        // concatenated, no age, and an IsActive flag computed from the row
        // age -- a shape no other implementation used.
        await SendAsync(user, cancellation: ct);
    }
}
