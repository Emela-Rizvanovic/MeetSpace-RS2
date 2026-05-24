using MeetSpace.Models.Requests;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        [HttpPost("create-intent")]
        public async Task<IActionResult> CreatePaymentIntent(
     CreatePaymentIntentRequest request,
     CancellationToken ct)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);

            var result = await _paymentService.CreatePaymentIntentAsync(
                request,
                currentUserId,
                ct);

            return Ok(result);
        }

        [HttpPost("confirm")]
        public async Task<IActionResult> ConfirmPayment(
          ConfirmPaymentRequest request,
          CancellationToken ct)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);

            var result = await _paymentService.ConfirmPaymentAsync(
                request,
                currentUserId,
                ct);

            return Ok(result);
        }
    }
}