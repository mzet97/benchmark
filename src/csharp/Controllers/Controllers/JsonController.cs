using BenchmarkControllers.Models;
using Microsoft.AspNetCore.Mvc;

namespace BenchmarkControllers.Controllers;

[ApiController]
public class JsonController : ControllerBase
{
    [HttpGet("/json")]
    public IActionResult GetJson([FromQuery] string? n)
    {
        return Ok(Canonical.Response(n));
    }
}
