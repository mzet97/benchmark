using BenchmarkApi.Models;
using BenchmarkApi.Services;

namespace BenchmarkApi.Handlers;

public static class ComplexDbHandler
{
    public static async Task<IResult> GetComplexDbAsync(
        int? days,
        IDatabaseService databaseService,
        ILogger logger)
    {
        var queryDays = days ?? 30;

        if (queryDays <= 0 || queryDays > 365)
        {
            return Results.BadRequest(new { error = "Days must be between 1 and 365" });
        }

        logger.LogInformation("Complex DB query requested for last {Days} days", queryDays);
        var results = await databaseService.GetComplexQueryAsync(queryDays);

        return Results.Ok(new
        {
            periodDays = queryDays,
            totalUsers = results.Length,
            data = results
        });
    }
}
