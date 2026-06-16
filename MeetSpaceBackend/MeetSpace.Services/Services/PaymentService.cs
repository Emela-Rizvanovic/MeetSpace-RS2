using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Exceptions;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Stripe;
using System.Text.Json;
using MeetSpace.Models.Messages;
using MeetSpace.Models.Constants;

namespace MeetSpace.Services.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly MeetSpaceDbContext _context;
        private readonly IBookingService _bookingService;
        private readonly IRabbitMQService _rabbitMq;

        public PaymentService(
     MeetSpaceDbContext context,
     IBookingService bookingService,
     IRabbitMQService rabbitMq)
        {
            _context = context;
            _bookingService = bookingService;
            _rabbitMq = rabbitMq;
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(
            CreatePaymentIntentRequest request,
            int currentUserId,
            CancellationToken ct = default)
        {
           var amount = await _bookingService.ValidateCreatePrerequisitesAndCalculatePriceAsync(
    request.SpaceId,
    request.StartTime,
    request.EndTime,
    request.Amenities,
    ct);

            var options = new PaymentIntentCreateOptions
            {
                Amount = (long)(amount * 100),
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
                Amount = amount,
                Currency = request.Currency,
                IsCompleted = false,
                UserId = currentUserId,
                SpaceId = request.SpaceId,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                AmenitiesSnapshotJson = JsonSerializer.Serialize(request.Amenities),
                Provider = "Stripe",
                Status = "Created",
                ExpiresAt = DateTime.UtcNow.AddMinutes(30),
            };

            _context.PaymentIntents.Add(paymentIntent);
            await _context.SaveChangesAsync(ct);

            return new PaymentIntentResponse
            {
                ClientSecret = stripeIntent.ClientSecret,
                PaymentIntentId = paymentIntent.Id,
                Amount = amount
            };
        }

        public async Task<ConfirmPaymentResponse> ConfirmPaymentAsync(
            ConfirmPaymentRequest request,
            int currentUserId,
            CancellationToken ct = default)
        {
            var paymentIntent = await _context.PaymentIntents
    .FirstOrDefaultAsync(x =>
        x.Id == request.PaymentIntentId &&
        x.UserId == currentUserId &&
        x.Provider == "Stripe",
        ct);

            if (paymentIntent == null)
                throw new NotFoundException("Payment intent not found");

            if (paymentIntent.ExpiresAt <= DateTime.UtcNow)
                throw new BusinessException("Payment intent has expired.");

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

            var amenities = JsonSerializer.Deserialize<List<BookingAmenityInsertRequest>>(
    paymentIntent.AmenitiesSnapshotJson
) ?? new();

            try
            {
                var expectedAmount = await _bookingService.ValidateCreatePrerequisitesAndCalculatePriceAsync(
                    paymentIntent.SpaceId,
                    paymentIntent.StartTime,
                    paymentIntent.EndTime,
                    amenities,
                    ct);

                var authorizedAmount = Math.Round((decimal)stripeIntent.AmountCapturable / 100m, 2);

                if (paymentIntent.Amount != expectedAmount || authorizedAmount != expectedAmount)
                    throw new BusinessException("Authorized amount does not match booking price.");

                await using var transaction = await _context.Database.BeginTransactionAsync(ct);

                var bookingRequest = new BookingInsertRequest
                {
                    SpaceId = paymentIntent.SpaceId,
                    UserId = currentUserId,
                    InternalPaymentStatus = PaymentStatusEnum.Authorized,
                    StartTime = paymentIntent.StartTime,
                    EndTime = paymentIntent.EndTime,
                    Amenities = amenities
                };

                var bookingResponse = await _bookingService.CreateAsync(bookingRequest, ct);

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

                paymentIntent.Status = "Authorized";

                await _context.SaveChangesAsync(ct);

                await transaction.CommitAsync(ct);

                await _rabbitMq.PublishAsync(new BookingStatusChangedMessage
                {
                    UserId = currentUserId,
                    SpaceName = bookingResponse.SpaceName,
                    StartTime = bookingResponse.StartTime,
                    RelatedBookingId = bookingResponse.Id,
                    NotificationType = NotificationTypeEnum.PaymentAuthorized
                }, "meetspace.booking-status");

                var currentUser = await _context.Users
    .FirstOrDefaultAsync(x => x.Id == currentUserId, ct);

                var admins = await _context.Users
                    .Where(x => x.Role.Name == Roles.Admin && x.IsActive)
                    .ToListAsync(ct);

                foreach (var admin in admins)
                {
                    await _rabbitMq.PublishAsync(new BookingStatusChangedMessage
                    {
                        UserId = admin.Id,
                        SpaceName = bookingResponse.SpaceName,
                        StartTime = bookingResponse.StartTime,
                        RelatedBookingId = bookingResponse.Id,
                        ActorUsername = currentUser?.Username,
                        NotificationType = NotificationTypeEnum.BookingCreated
                    }, "meetspace.booking-status");
                }

                return new ConfirmPaymentResponse
                {
                    BookingId = bookingResponse.Id
                };
            }
            catch
            {
                await service.CancelAsync(paymentIntent.StripePaymentIntentId, cancellationToken: ct);

                paymentIntent.Status = "Failed";
                await _context.SaveChangesAsync(ct);

                throw;
            }
        }
    }

}