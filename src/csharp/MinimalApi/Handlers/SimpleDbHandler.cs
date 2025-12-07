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

        var userDto = new UserDto
        {
            Id = user.Id,
            Name = $"{user.FirstName} {user.LastName}",
            Email = user.Email,
            CreatedAt = user.CreatedAt,
            IsActive = user.CreatedAt > DateTime.UtcNow.AddYears(-1)
        };

        return Results.Ok(userDto);
    }
}
