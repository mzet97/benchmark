using Microsoft.AspNetCore.Mvc;

namespace BenchmarkControllers.Controllers;

[ApiController]
public class HealthController : ControllerBase
{
    [HttpGet("/health")]
    public IActionResult GetHealth()
    {
        return Ok(new { status = "ok", version = "1.0.0", timestamp = DateTime.UtcNow });
    }

    [HttpGet("/healthz")]
    public IActionResult GetLiveness()
    {
        return Ok(new { status = "ok" });
    }

    [HttpGet("/readyz")]
    public IActionResult GetReadiness()
    {
        return Ok(new { status = "ready" });
    }
}
