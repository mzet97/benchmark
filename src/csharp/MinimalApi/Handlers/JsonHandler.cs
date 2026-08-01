using BenchmarkApi.Models;

namespace BenchmarkApi.Handlers;

public static class JsonHandler
{
    // n is bound from the query string by the minimal-API parameter binder.
    public static IResult GetJson(string? n)
    {
        return Results.Ok(Canonical.Response(n));
    }
}
