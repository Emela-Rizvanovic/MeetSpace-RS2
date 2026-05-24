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

            var service = new PaymentIntentService();
            var stripeIntent = await service.GetAsync(paymentIntent.StripePaymentIntentId);

            if (stripeIntent.Status != "succeeded")
                throw new BusinessException("Payment not completed");

            await using var transaction = await _context.Database.BeginTransactionAsync(ct);

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
                await _bookingService.CreateAsync(bookingRequest, ct);

            await _context.SaveChangesAsync(ct);

            var payment = new Payment
            {
                BookingId = bookingResponse.Id,
                UserId = currentUserId,
                PaymentIntentId = paymentIntent.Id,
                PaymentMethodId = (int)PaymentMethodEnum.Stripe,
                PaymentStatusId = (int)PaymentStatusEnum.Completed,
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
    }
}