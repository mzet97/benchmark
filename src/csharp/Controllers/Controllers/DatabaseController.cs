using BenchmarkControllers.Services;
using Microsoft.AspNetCore.Mvc;

namespace BenchmarkControllers.Controllers;

[ApiController]
public class DatabaseController : ControllerBase
{
    private readonly IDatabaseService _databaseService;
    private readonly ILogger<DatabaseController> _logger;

    public DatabaseController(IDatabaseService databaseService, ILogger<DatabaseController> logger)
    {
        _databaseService = databaseService;
        _logger = logger;
    }

    [HttpGet("/db/simple")]
    public async Task<IActionResult> GetSimpleDb([FromQuery] int? id)
    {
        if (!id.HasValue || id <= 0)
        {
            return BadRequest(new { error = "Invalid id parameter" });
        }

        _logger.LogInformation("Simple DB query requested for id: {Id}", id);
        var user = await _databaseService.GetUserByIdAsync(id.Value);

        if (user == null)
        {
            return NotFound(new { error = $"User with id {id} not found" });
        }
        // The contract returns the user object itself. The previous DTO was
        // {Id, Name, Email, CreatedAt, IsActive}: first and last name
        // concatenated, no age, and an IsActive flag computed from the row
        // age -- a shape no other implementation used.
        return Ok(user);
    }

    [HttpGet("/db/complex")]
    public async Task<IActionResult> GetComplexDb([FromQuery] int? days)
    {
        var queryDays = days ?? 30;

        if (queryDays <= 0 || queryDays > 365)
        {
            return BadRequest(new { error = "Days must be between 1 and 365" });
        }

        _logger.LogInformation("Complex DB query requested for last {Days} days", queryDays);
        var results = await _databaseService.GetComplexQueryAsync(queryDays);

        return Ok(new
        {
            periodDays = queryDays,
            totalUsers = results.Length,
            data = results
        });
    }
}
