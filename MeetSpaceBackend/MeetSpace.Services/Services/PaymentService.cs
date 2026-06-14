using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Exceptions;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace MeetSpace.Services.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly MeetSpaceDbContext _context;
        private readonly IBookingService _bookingService;

        public PaymentService(
            MeetSpaceDbContext context,
            IBookingService bookingService)
        {
            _context = context;
            _bookingService = bookingService;
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(
            CreatePaymentIntentRequest request,
            int currentUserId,
            CancellationToken ct = default)
        {
            var options = new PaymentIntentCreateOptions
            {
                Amount = (long)(request.Amount * 100),
                Currency = request.Currency,
                CaptureMethod = "manual",
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
            await _context.SaveChangesAsync(ct);

            return new PaymentIntentResponse
            {
                ClientSecret = stripeIntent.ClientSecret,
                PaymentIntentId = paymentIntent.Id
            };
        }

        public async Task<ConfirmPaymentResponse> ConfirmPaymentAsync(
            ConfirmPaymentRequest request,
            int currentUserId,
            CancellationToken ct = default)
        {
            var paymentIntent = await _context.PaymentIntents
                .FirstOrDefaultAsync(x => x.Id == request.PaymentIntentId, ct);

            if (paymentIntent == null)
                throw new NotFoundException("Payment intent not found");

            var existingPayment = await _context.Payments
      .FirstOrDefaultAsync(x => x.PaymentIntentId == paymentIntent.Id, ct);

            if (existingPayment != null)
            {
                return new ConfirmPaymentResponse
                {
                    BookingId = existingPayment.BookingId
                };
            }

            var service = new PaymentIntentService();
            var stripeIntent = await service.GetAsync(paymentIntent.StripePaymentIntentId);

            if (stripeIntent.Status != "requires_capture")
                throw new BusinessException("Payment was not authorized.");

            var expectedAmount = await CalculateExpectedAmountAsync(
    request.SpaceId,
    request.StartTime,
    request.EndTime,
    request.Amenities
        .Select(x => new BookingAmenityInsertRequest
        {
            AmenityId = x.AmenityId,
            Quantity = x.Quantity
        })
        .ToList(),
    ct);

            var authorizedAmount = Math.Round((decimal)stripeIntent.AmountCapturable / 100m, 2);

            if (paymentIntent.Amount != expectedAmount || authorizedAmount != expectedAmount)
                throw new BusinessException("Authorized amount does not match booking price.");

            await using var transaction = await _context.Database.BeginTransactionAsync(ct);

            var bookingRequest = new BookingInsertRequest
            {
                SpaceId = request.SpaceId,
                UserId = currentUserId,
                InternalPaymentStatus = PaymentStatusEnum.Authorized,
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
                await _bookingService.CreateAsync(bookingRequest, ct);

            await _context.SaveChangesAsync(ct);

            var payment = new Payment
            {
                BookingId = bookingResponse.Id,
                UserId = currentUserId,
                PaymentIntentId = paymentIntent.Id,
                PaymentMethodId = (int)PaymentMethodEnum.Stripe,
                PaymentStatusId = (int)PaymentStatusEnum.Authorized,
                Amount = paymentIntent.Amount,
                PaymentDate = DateTime.UtcNow
            };

            _context.Payments.Add(payment);

            await _context.SaveChangesAsync(ct);

            await transaction.CommitAsync(ct);

            return new ConfirmPaymentResponse
            {
                BookingId = bookingResponse.Id
            };
        }

        private async Task<decimal> CalculateExpectedAmountAsync(
    int spaceId,
    DateTime startTime,
    DateTime endTime,
    List<BookingAmenityInsertRequest> amenities,
    CancellationToken ct)
        {
            if (endTime <= startTime)
                throw new BusinessException("EndTime must be greater than StartTime.");

            var space = await _context.Spaces
                .FirstOrDefaultAsync(x => x.Id == spaceId, ct);

            if (space == null)
                throw new NotFoundException("Space not found.");

            var hours = (decimal)(endTime - startTime).TotalHours;
            var total = Math.Round(hours * space.PricePerHour, 2);

            foreach (var item in amenities)
            {
                var amenity = await _context.Amenities
                    .FirstOrDefaultAsync(x => x.Id == item.AmenityId, ct);

                if (amenity == null)
                    throw new NotFoundException($"Amenity {item.AmenityId} not found.");

                var quantity = item.Quantity <= 0 ? 1 : item.Quantity;
                total += Math.Round(amenity.Price * quantity, 2);
            }

            return Math.Round(total, 2);
        }
    }

}