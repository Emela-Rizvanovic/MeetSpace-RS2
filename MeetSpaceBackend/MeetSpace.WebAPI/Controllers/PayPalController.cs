using MeetSpace.Models.Requests;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class PayPalController : ControllerBase
{
    private readonly IPayPalService _payPalService;
    public PayPalController(IPayPalService payPalService)
    {
        _payPalService = payPalService;
    }

    [HttpPost("create-order")]
    public async Task<IActionResult> CreateOrder(
      [FromBody] CreatePayPalOrderRequest request,
      CancellationToken ct)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        int currentUserId = int.Parse(userIdClaim.Value);

        var result = await _payPalService.CreateOrderAsync(request, currentUserId, ct);

        return Ok(result);
    }

    [HttpPost("capture")]
    public async Task<IActionResult> Capture(
        [FromBody] PayPalCaptureRequest request,
        CancellationToken ct)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        int currentUserId = int.Parse(userIdClaim.Value);

        var result = await _payPalService.CaptureAsync(
            request,
            currentUserId,
            ct);

        return Ok(result);
    }
}