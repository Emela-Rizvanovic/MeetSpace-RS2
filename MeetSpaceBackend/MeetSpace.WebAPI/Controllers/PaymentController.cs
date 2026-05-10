using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly MeetSpaceDbContext _context;
        private readonly IBookingService _bookingService;

        public PaymentController(
            MeetSpaceDbContext context,
            IBookingService bookingService)
        {
            _context = context;
            _bookingService = bookingService;
        }

        [HttpPost("create-intent")]
        public async Task<IActionResult> CreatePaymentIntent(CreatePaymentIntentRequest request)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);

            var options = new PaymentIntentCreateOptions
            {
                Amount = (long)(request.Amount * 100),
                Currency = request.Currency,
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                }
            };

            var service = new PaymentIntentService();
            var stripeIntent = await service.CreateAsync(options);

            var paymentIntent = new MeetSpace.Models.Entities.PaymentIntent
            {
                StripePaymentIntentId = stripeIntent.Id,
                Amount = request.Amount,
                Currency = request.Currency,
                IsCompleted = false
            };

            _context.PaymentIntents.Add(paymentIntent);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                clientSecret = stripeIntent.ClientSecret,
                paymentIntentId = paymentIntent.Id
            });
        }

        [HttpPost("confirm")]
        public async Task<IActionResult> ConfirmPayment(ConfirmPaymentRequest request)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);

            var paymentIntent = await _context.PaymentIntents
                .FirstOrDefaultAsync(x => x.Id == request.PaymentIntentId);

            if (paymentIntent == null)
                return BadRequest("Payment intent not found");

            var service = new PaymentIntentService();
            var stripeIntent = await service.GetAsync(paymentIntent.StripePaymentIntentId);

            if (stripeIntent.Status != "succeeded")
                return BadRequest("Payment not completed");

            paymentIntent.IsCompleted = true;

            var bookingRequest = new BookingInsertRequest
            {
                SpaceId = request.SpaceId,
                UserId = currentUserId,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                Amenities = request.Amenities
         .Select(x => new BookingAmenityInsertRequest
         {
             AmenityId = x.AmenityId,
             Quantity = x.Quantity
         })
         .ToList()
            };

            var bookingResponse =
                await _bookingService.CreateAsync(bookingRequest);

            await _context.SaveChangesAsync();

            var payment = new Payment
            {
                BookingId = bookingResponse.Id,
                UserId = currentUserId,
                PaymentIntentId = paymentIntent.Id,
                PaymentMethodId = 1, // Stripe
                PaymentStatusId = 2, // Completed
                Amount = paymentIntent.Amount,
                PaymentDate = DateTime.UtcNow
            };

            _context.Payments.Add(payment);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                bookingId = bookingResponse.Id
            });
        }
    }
}