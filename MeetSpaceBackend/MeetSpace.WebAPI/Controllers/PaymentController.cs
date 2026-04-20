using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Services.Database;
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

        public PaymentController(MeetSpaceDbContext context)
        {
            _context = context;
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

            var space = await _context.Spaces
                .FirstOrDefaultAsync(x => x.Id == request.SpaceId);

            if (space == null)
                return BadRequest("Space not found");

            var hours = (request.EndTime - request.StartTime).TotalHours;

            decimal total = space.PricePerHour * (decimal)hours;

            foreach (var a in request.Amenities)
            {
                var amenity = await _context.Amenities
                    .FirstOrDefaultAsync(x => x.Id == a.AmenityId);

                if (amenity != null)
                {
                    total += amenity.Price * a.Quantity;
                }
            }

            var booking = new Booking
            {
                SpaceId = request.SpaceId,
                UserId = currentUserId,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                BookingStatusId = 1, // Pending
                PaymentStatusId = 2, //Completed
                TotalPrice = total 
            };

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync(); 

            foreach (var a in request.Amenities)
            {
                var bookingAmenity = new BookingAmenity
                {
                    BookingId = booking.Id,
                    AmenityId = a.AmenityId,
                    Quantity = a.Quantity
                };

                _context.BookingAmenities.Add(bookingAmenity);
            }

            var payment = new Payment
            {
                BookingId = booking.Id,
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
                bookingId = booking.Id
            });
        }
    }
}