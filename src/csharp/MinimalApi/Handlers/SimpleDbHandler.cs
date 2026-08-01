using BenchmarkApi.Models;
using BenchmarkApi.Services;

namespace BenchmarkApi.Handlers;

public static class SimpleDbHandler
{
    public static async Task<IResult> GetSimpleDbAsync(
        int? id,
        IDatabaseService databaseService,
        ILogger logger)
    {
        if (!id.HasValue || id <= 0)
        {
            return Results.BadRequest(new { error = "Invalid id parameter" });
        }

        logger.LogInformation("Simple DB query requested for id: {Id}", id);
        var user = await databaseService.GetUserByIdAsync(id.Value);

        if (user == null)
        {
            return Results.NotFound(new { error = $"User with id {id} not found" });
        }
        // The contract returns the user object itself. The previous DTO was
        // {Id, Name, Email, CreatedAt, IsActive}: first and last name
        // concatenated, no age, and an IsActive flag computed from the row
        // age -- a shape no other implementation used.
        return Results.Ok(user);
    }
}
