using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Messages;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore.Storage;
using MeetSpace.Models.Exceptions;
using MeetSpace.Models.Constants;
using Stripe;
using Newtonsoft.Json.Linq;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace MeetSpace.Services.Services
{
    public class BookingService : BaseCRUDService<BookingResponse, BookingSearchObject, Booking, BookingInsertRequest, BookingUpdateRequest>, IBookingService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IRabbitMQService _rabbitMq;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly string _payPalClientId;
        private readonly string _payPalSecret;
        public BookingService(
     MeetSpaceDbContext context,
     IMapper mapper,
     IHttpContextAccessor httpContextAccessor,
     IRabbitMQService rabbitMq,
     IHttpClientFactory httpClientFactory)
     : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
            _rabbitMq = rabbitMq;
            _httpClientFactory = httpClientFactory;
            _payPalClientId = Environment.GetEnvironmentVariable("PAYPAL_CLIENT_ID")!;
            _payPalSecret = Environment.GetEnvironmentVariable("PAYPAL_SECRET")!;
        }

        protected override IQueryable<Booking> ApplyFilter(IQueryable<Booking> query, BookingSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(b => b.UserId == search.UserId.Value);

            if (search.SpaceId.HasValue)
                query = query.Where(b => b.SpaceId == search.SpaceId.Value);

            if (search.BookingStatusId.HasValue)
                query = query.Where(b => b.BookingStatusId == search.BookingStatusId.Value);

            if (search.StartFrom.HasValue)
                query = query.Where(b => b.StartTime >= search.StartFrom.Value);

            if (search.StartTo.HasValue)
                query = query.Where(b => b.StartTime <= search.StartTo.Value);

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(b =>
                    b.Space.Name.Contains(search.Name) ||
                    b.User.Username.Contains(search.Name));
            }

            if (search.IsUpcoming.HasValue)
            {
                if (search.IsUpcoming.Value)
                {
                    query = query.Where(b => b.StartTime >= DateTime.Now);
                }
                else
                {
                    query = query.Where(b => b.StartTime < DateTime.Now);
                }
            }

            return query
                .Include(b => b.Space)
                    .ThenInclude(s => s.Facility)
                .Include(b => b.Space)
        .ThenInclude(s => s.Images)
                .Include(b => b.BookingStatus)
                .Include(b => b.User)
                .Include(b => b.PaymentStatus);
        }

        public async Task<decimal> ValidateCreatePrerequisitesAndCalculatePriceAsync(
    int spaceId,
    DateTime startTime,
    DateTime endTime,
    List<BookingAmenityInsertRequest>? amenities,
    CancellationToken ct = default)
        {
            if (endTime <= startTime)
                throw new BusinessException("EndTime must be greater than StartTime.");

            if (startTime <= DateTime.UtcNow)
                throw new BusinessException("Booking start time must be in the future.");

            var hasConflict = await _context.Bookings
                .AnyAsync(b =>
                    b.SpaceId == spaceId &&
                    b.BookingStatusId != (int)BookingStatusEnum.Rejected &&
                    b.BookingStatusId != (int)BookingStatusEnum.Cancelled &&
                    startTime < b.EndTime &&
                    endTime > b.StartTime,
                    ct);

            if (hasConflict)
                throw new BusinessException("Time slot already booked.");

            var space = await _context.Spaces
                .FirstOrDefaultAsync(s => s.Id == spaceId && s.IsActive, ct);

            if (space == null)
                throw new NotFoundException("Space not found.");

            var hours = (decimal)(endTime - startTime).TotalHours;

            if (hours <= 0)
                throw new BusinessException("Invalid booking duration.");

            var total = Math.Round(hours * space.PricePerHour, 2);

            if (amenities != null && amenities.Any())
            {
                foreach (var item in amenities)
                {
                    var amenity = await _context.Amenities
                        .FirstOrDefaultAsync(a => a.Id == item.AmenityId, ct);

                    if (amenity == null)
                        throw new NotFoundException($"Amenity {item.AmenityId} not found.");

                    var quantity = item.Quantity <= 0 ? 1 : item.Quantity;
                    total += Math.Round(amenity.Price * quantity, 2);
                }
            }

            return Math.Round(total, 2);
        }

        protected override async Task BeforeInsert(
    Booking entity,
    BookingInsertRequest request,
    CancellationToken cancellationToken = default)
        {
            entity.CreatedAt = DateTime.UtcNow;

            entity.TotalPrice = await ValidateCreatePrerequisitesAndCalculatePriceAsync(
      request.SpaceId,
      request.StartTime,
      request.EndTime,
      request.Amenities,
      cancellationToken);

            if (request.Amenities != null && request.Amenities.Any())
            {
                foreach (var item in request.Amenities)
                {
                    var amenity = await _context.Amenities
                        .FirstOrDefaultAsync(a => a.Id == item.AmenityId, cancellationToken);

                    if (amenity == null)
                        throw new NotFoundException($"Amenity {item.AmenityId} not found.");

                    var quantity = item.Quantity <= 0 ? 1 : item.Quantity;

                    entity.BookingAmenities.Add(new BookingAmenity
                    {
                        AmenityId = amenity.Id,
                        Quantity = quantity,
                        Price = amenity.Price
                    });
                }
            }

            entity.PaymentStatusId = request.InternalPaymentStatus.HasValue
    ? (int)request.InternalPaymentStatus.Value
    : (int)PaymentStatusEnum.Pending;

            entity.BookingStatusId = (int)BookingStatusEnum.Pending;

            await base.BeforeInsert(entity, request, cancellationToken);
        }

        protected override async Task BeforeUpdate(
      Booking entity,
      BookingUpdateRequest request,
      CancellationToken cancellationToken = default)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            var start = request.StartTime ?? entity.StartTime;
            var end = request.EndTime ?? entity.EndTime;
            var spaceId = request.SpaceId ?? entity.SpaceId;
            var userId = request.UserId ?? entity.UserId;
            var bookingStatusId = request.BookingStatusId ?? entity.BookingStatusId;

            var amenities = request.Amenities;

            entity.TotalPrice = await ValidateUpdatePrerequisitesAndCalculatePriceAsync(
                entity.Id,
                spaceId,
                start,
                end,
                amenities,
                cancellationToken);

            entity.SpaceId = spaceId;
            entity.UserId = userId;
            entity.BookingStatusId = bookingStatusId;
            entity.StartTime = start;
            entity.EndTime = end;

            if (amenities != null)
            {
                _context.BookingAmenities.RemoveRange(entity.BookingAmenities);
                entity.BookingAmenities.Clear();

                foreach (var item in amenities)
                {
                    var amenity = await _context.Amenities
                        .FirstOrDefaultAsync(a => a.Id == item.AmenityId, cancellationToken);

                    if (amenity == null)
                        throw new NotFoundException($"Amenity {item.AmenityId} not found.");

                    var quantity = item.Quantity <= 0 ? 1 : item.Quantity;

                    entity.BookingAmenities.Add(new BookingAmenity
                    {
                        BookingId = entity.Id,
                        AmenityId = amenity.Id,
                        Quantity = quantity,
                        Price = amenity.Price
                    });
                }
            }

            await base.BeforeUpdate(entity, request, cancellationToken);
        }

        private async Task<decimal> ValidateUpdatePrerequisitesAndCalculatePriceAsync(
    int bookingId,
    int spaceId,
    DateTime startTime,
    DateTime endTime,
    List<BookingAmenityInsertRequest>? amenities,
    CancellationToken ct = default)
        {
            if (endTime <= startTime)
                throw new BusinessException("EndTime must be greater than StartTime.");

            if (startTime <= DateTime.UtcNow)
                throw new BusinessException("Booking start time must be in the future.");

            var hasConflict = await _context.Bookings
                .AnyAsync(b =>
                    b.Id != bookingId &&
                    b.SpaceId == spaceId &&
                    b.BookingStatusId != (int)BookingStatusEnum.Rejected &&
                    b.BookingStatusId != (int)BookingStatusEnum.Cancelled &&
                    startTime < b.EndTime &&
                    endTime > b.StartTime,
                    ct);

            if (hasConflict)
                throw new BusinessException("Time slot already booked.");

            var space = await _context.Spaces
                .FirstOrDefaultAsync(s => s.Id == spaceId && s.IsActive, ct);

            if (space == null)
                throw new NotFoundException("Space not found.");

            var hours = (decimal)(endTime - startTime).TotalHours;

            if (hours <= 0)
                throw new BusinessException("Invalid booking duration.");

            var total = Math.Round(hours * space.PricePerHour, 2);

            if (amenities != null && amenities.Any())
            {
                foreach (var item in amenities)
                {
                    var amenity = await _context.Amenities
                        .FirstOrDefaultAsync(a => a.Id == item.AmenityId, ct);

                    if (amenity == null)
                        throw new NotFoundException($"Amenity {item.AmenityId} not found.");

                    var quantity = item.Quantity <= 0 ? 1 : item.Quantity;
                    total += Math.Round(amenity.Price * quantity, 2);
                }
            }
            else if (amenities == null)
            {
                var existingAmenitiesTotal = await _context.BookingAmenities
                    .Where(x => x.BookingId == bookingId)
                    .SumAsync(x => x.Price * x.Quantity, ct);

                total += existingAmenitiesTotal;
            }

            return Math.Round(total, 2);
        }

        public override async Task<BookingResponse> CreateAsync(BookingInsertRequest request, CancellationToken cancellationToken = default)
        {
            var ownsTransaction = _context.Database.CurrentTransaction == null;

            IDbContextTransaction? transaction = ownsTransaction
                ? await _context.Database.BeginTransactionAsync(cancellationToken)
                : null;

            var entity = _mapper.Map<Booking>(request);

            await BeforeInsert(entity, request, cancellationToken);

            _context.Bookings.Add(entity);
            await _context.SaveChangesAsync(cancellationToken);


            var log = await _context.RecommendationLogs
                .Where(r => r.UserId == entity.UserId && r.SpaceId == entity.SpaceId)
                .OrderByDescending(r => r.RecommendedAt)
                .FirstOrDefaultAsync(cancellationToken);

            if (log != null)
            {
                log.Booked = true;
                await _context.SaveChangesAsync(cancellationToken);
            }

            var loaded = await _context.Bookings
                .Include(b => b.Space).ThenInclude(s => s.Facility)
                .Include(b => b.Space)
        .ThenInclude(s => s.Images)
                .Include(b => b.BookingStatus)
                .Include(b => b.User)
                .Include(b => b.PaymentStatus)
                .FirstAsync(b => b.Id == entity.Id, cancellationToken);

            if (transaction != null)
            {
                await transaction.CommitAsync(cancellationToken);
                await transaction.DisposeAsync();
            }

            return await MapWithAuditAsync(loaded, cancellationToken);
        }


        public override async Task<BookingResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Bookings
                .Include(b => b.Space).ThenInclude(s => s.Facility)
                .Include(b => b.Space)
        .ThenInclude(s => s.Images)
                .Include(b => b.BookingStatus)
                .Include(b => b.User)
                .Include(b => b.PaymentStatus)
                .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);

            return entity == null ? null : await MapWithAuditAsync(entity, cancellationToken);
        }

        public async Task<List<BookingAvailabilityResponse>> GetAvailabilityBySpaceIdAsync(int spaceId, CancellationToken ct = default)
        {
            return await _context.Bookings
                .Where(b =>
                    b.SpaceId == spaceId &&
                    b.BookingStatusId != (int)BookingStatusEnum.Rejected &&
                    b.BookingStatusId != (int)BookingStatusEnum.Cancelled)
                .OrderBy(b => b.StartTime)
                .Select(b => new BookingAvailabilityResponse
                {
                    StartTime = b.StartTime,
                    EndTime = b.EndTime,
                    Status = AvailabilityStatuses.Busy
                })
                .ToListAsync(ct);
        }

        public override async Task<BookingResponse?> UpdateAsync(int id, BookingUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Bookings
    .Include(b => b.BookingAmenities)
    .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);

            if (entity == null)
                return null;

            await BeforeUpdate(entity, request, cancellationToken);

            await _context.SaveChangesAsync(cancellationToken);

            var loaded = await _context.Bookings
                .Include(b => b.Space).ThenInclude(s => s.Facility)
                .Include(b => b.Space)
        .ThenInclude(s => s.Images)
                .Include(b => b.BookingStatus)
                .Include(b => b.User)
                .Include(b => b.PaymentStatus)
                .FirstAsync(b => b.Id == id, cancellationToken);

            return await MapWithAuditAsync(loaded, cancellationToken);
        }


        public async Task<List<BookingResponse>> GetByUserIdAsync(int userId, CancellationToken ct = default)
        {
            var list = await _context.Bookings
                .Include(b => b.Space).ThenInclude(s => s.Facility)
                .Include(b => b.Space)
        .ThenInclude(s => s.Images)
                .Include(b => b.BookingStatus)
                .Include(b => b.User)
                .Where(b => b.UserId == userId)
                .Include(b => b.PaymentStatus)
                .OrderByDescending(b => b.StartTime)
                .ToListAsync(ct);

            return await MapWithAuditListAsync(list, ct);
        }

        public async Task<List<BookingResponse>> GetBySpaceIdAsync(int spaceId, CancellationToken ct = default)
        {
            var list = await _context.Bookings
                .Include(b => b.Space)
                    .ThenInclude(s => s.Facility)
                    .Include(b => b.Space)
        .ThenInclude(s => s.Images)
                .Include(b => b.BookingStatus)
                .Include(b => b.User)
                .Where(b => b.SpaceId == spaceId)
                .Include(b => b.PaymentStatus)
                .OrderBy(b => b.StartTime)
                .ToListAsync(ct);

            return await MapWithAuditListAsync(list, ct);
        }

        public async Task ApproveAsync(int id, CancellationToken ct = default)
        {
            var entity = await _context.Bookings
    .Include(b => b.User)
    .Include(b => b.Space)
    .Include(b => b.Payments)
    .FirstOrDefaultAsync(b => b.Id == id, ct);

            if (entity == null)
                throw new NotFoundException("Booking not found");

            ValidateStatusTransition(
    entity.BookingStatusId,
    BookingStatusEnum.Approved
);

            await CaptureAuthorizedPaymentAsync(entity, ct);

            if (entity.PaymentStatusId != (int)PaymentStatusEnum.Completed)
                throw new BusinessException("Booking payment must be captured before approval.");

            entity.BookingStatusId = (int)BookingStatusEnum.Approved;

            var userId = int.Parse(
                _httpContextAccessor.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier).Value
            );

            _context.BookingAuditLogs.Add(new BookingAuditLog
            {
                BookingId = entity.Id,
                AdminId = userId,
                Action = "Approved",
                Comment = "Booking approved by administrator.",
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync(ct);

            await _rabbitMq.PublishAsync(new BookingStatusChangedMessage
            {
                UserId = entity.UserId,
                SpaceName = entity.Space.Name,
                StartTime = entity.StartTime,
                IsApproved = true,
                RelatedBookingId = entity.Id
            }, "meetspace.booking-status");

            await _rabbitMq.PublishAsync(new BookingStatusChangedMessage
            {
                UserId = entity.UserId,
                SpaceName = entity.Space.Name,
                StartTime = entity.StartTime,
                RelatedBookingId = entity.Id,
                NotificationType = NotificationTypeEnum.PaymentCompleted
            }, "meetspace.booking-status");
        }

        public async Task RejectAsync(int id, string reason, CancellationToken ct = default)
        {
            var entity = await _context.Bookings
    .Include(b => b.User)
    .Include(b => b.Space)
    .Include(b => b.Payments)
    .FirstOrDefaultAsync(b => b.Id == id, ct);

            if (entity == null)
                throw new NotFoundException("Booking not found");

            ValidateStatusTransition(
    entity.BookingStatusId,
    BookingStatusEnum.Rejected
);

            await VoidAuthorizedPaymentAsync(entity, ct);

            entity.BookingStatusId = (int)BookingStatusEnum.Rejected;
            entity.RejectionReason = reason;

            var userId = int.Parse(
                _httpContextAccessor.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier).Value
            );

            _context.BookingAuditLogs.Add(new BookingAuditLog
            {
                BookingId = entity.Id,
                AdminId = userId,
                Action = "Rejected",
                Comment = reason,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync(ct);


            await _rabbitMq.PublishAsync(new BookingStatusChangedMessage
            {
                UserId = entity.UserId,
                SpaceName = entity.Space.Name,
                StartTime = entity.StartTime,
                IsApproved = false,
                Reason = reason,
                RelatedBookingId = entity.Id
            }, "meetspace.booking-status");
        }

        public async Task CancelAsync(int id, string reason, CancellationToken ct = default)
        {
            var entity = await _context.Bookings
     .Include(b => b.User)
     .Include(b => b.Space)
     .Include(b => b.Payments)
     .FirstOrDefaultAsync(b => b.Id == id, ct);

            if (entity == null)
                throw new NotFoundException("Booking not found");

            var userId = int.Parse(
                _httpContextAccessor.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier).Value
            );

            var role = _httpContextAccessor.HttpContext.User
                .FindFirst(ClaimTypes.Role)?.Value;

            if (role != Roles.Admin && entity.UserId != userId)
                throw new UnauthorizedAccessException("You cannot cancel this booking.");

            if (entity.StartTime <= DateTime.UtcNow)
                throw new BusinessException("Only future bookings can be cancelled.");

            var requiresManualPaymentReview =
    entity.BookingStatusId == (int)BookingStatusEnum.Approved &&
    entity.PaymentStatusId == (int)PaymentStatusEnum.Completed;

            ValidateStatusTransition(
     entity.BookingStatusId,
     BookingStatusEnum.Cancelled
 );

            await VoidAuthorizedPaymentAsync(entity, ct);

            entity.BookingStatusId = (int)BookingStatusEnum.Cancelled;
            entity.RejectionReason = reason;

            _context.BookingAuditLogs.Add(new BookingAuditLog
            {
                BookingId = entity.Id,
                AdminId = userId,
                Action = role == Roles.Admin ? "Cancelled by admin" : "Cancelled by user",
                Comment = reason,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync(ct);

            if (role == Roles.Admin)
            {
                await _rabbitMq.PublishAsync(new BookingStatusChangedMessage
                {
                    UserId = entity.UserId,
                    SpaceName = entity.Space.Name,
                    StartTime = entity.StartTime,
                    IsApproved = false,
                    IsCancellation = true,
                    Reason = reason,
                    RelatedBookingId = entity.Id,
                    RequiresManualPaymentReview = requiresManualPaymentReview
                }, "meetspace.booking-status");
            }
            else
            {
                var admins = await _context.Users
                    .Where(x => x.Role.Name == Roles.Admin && x.IsActive)
                    .ToListAsync(ct);

                foreach (var admin in admins)
                {
                    await _rabbitMq.PublishAsync(new BookingStatusChangedMessage
                    {
                        UserId = admin.Id,
                        SpaceName = entity.Space.Name,
                        StartTime = entity.StartTime,
                        Reason = reason,
                        RelatedBookingId = entity.Id,
                        ActorUsername = entity.User.Username,
                        NotificationType = NotificationTypeEnum.UserBookingCancelled,
                        RequiresManualPaymentReview = requiresManualPaymentReview
                    }, "meetspace.booking-status");
                }
            }
        }

        public async Task<bool> HasConflict(int spaceId, DateTime start, DateTime end, int? ignoreId = null)
        {
            return await _context.Bookings
                .AnyAsync(b =>
                    b.SpaceId == spaceId &&
                    b.BookingStatusId != (int)BookingStatusEnum.Rejected &&
b.BookingStatusId != (int)BookingStatusEnum.Cancelled &&
                    (ignoreId == null || b.Id != ignoreId) &&
                    start < b.EndTime &&
                    end > b.StartTime
                );
        }

        private void ValidateStatusTransition(
    int currentStatusId,
    BookingStatusEnum newStatus)
        {
            var currentStatus = (BookingStatusEnum)currentStatusId;

            var isAllowed =
     currentStatus == BookingStatusEnum.Pending &&
     (
         newStatus == BookingStatusEnum.Approved ||
         newStatus == BookingStatusEnum.Rejected ||
         newStatus == BookingStatusEnum.Cancelled
     )
     ||
     currentStatus == BookingStatusEnum.Approved &&
     newStatus == BookingStatusEnum.Cancelled;

            if (!isAllowed)
            {
                throw new BusinessException(
                    $"Booking status cannot be changed from {currentStatus} to {newStatus}."
                );
            }
        }

        private async Task CaptureAuthorizedPaymentAsync(Booking entity, CancellationToken ct = default)
        {
            if (entity.PaymentStatusId == (int)PaymentStatusEnum.Completed)
                return;

            var payment = entity.Payments
                .FirstOrDefault(p => p.PaymentStatusId == (int)PaymentStatusEnum.Authorized);

            if (payment == null)
                throw new BusinessException("Booking does not have an authorized payment.");

            if (payment.PaymentMethodId == (int)PaymentMethodEnum.Stripe)
            {
                if (!payment.PaymentIntentId.HasValue)
                    throw new BusinessException("Stripe payment intent is missing.");

                var paymentIntent = await _context.PaymentIntents
                    .FirstOrDefaultAsync(x => x.Id == payment.PaymentIntentId.Value, ct);

                if (paymentIntent == null)
                    throw new NotFoundException("Stripe payment intent not found.");

                var stripeService = new PaymentIntentService();

                var capturedIntent = await stripeService.CaptureAsync(
                    paymentIntent.StripePaymentIntentId,
                    cancellationToken: ct);

                if (capturedIntent.Status != "succeeded")
                    throw new BusinessException("Stripe payment capture failed.");

                paymentIntent.IsCompleted = true;
            }
            else if (payment.PaymentMethodId == (int)PaymentMethodEnum.PayPal)
            {
                if (string.IsNullOrWhiteSpace(payment.ProviderAuthorizationId))
                    throw new BusinessException("PayPal authorization id is missing.");

                var client = _httpClientFactory.CreateClient();

                var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes(
                    $"{_payPalClientId}:{_payPalSecret}"
                ));

                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Basic", auth);

                var tokenResponse = await client.PostAsync(
                    "https://api-m.sandbox.paypal.com/v1/oauth2/token",
                    new FormUrlEncodedContent(new[]
                    {
            new KeyValuePair<string, string>("grant_type", "client_credentials")
                    }),
                    ct);

                var tokenJson = await tokenResponse.Content.ReadAsStringAsync(ct);
                var tokenData = JObject.Parse(tokenJson);
                string accessToken = tokenData["access_token"]?.ToString();

                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", accessToken);

                var captureResponse = await client.PostAsync(
                    $"https://api-m.sandbox.paypal.com/v2/payments/authorizations/{payment.ProviderAuthorizationId}/capture",
                    new StringContent("", Encoding.UTF8, "application/json"),
                    ct);

                var captureJson = await captureResponse.Content.ReadAsStringAsync(ct);
                var captureData = JObject.Parse(captureJson);

                var captureStatus = captureData["status"]?.ToString();

                if (captureStatus != "COMPLETED")
                    throw new BusinessException("PayPal payment capture failed.");
            }
            else
            {
                throw new BusinessException("Unsupported payment method.");
            }

            payment.PaymentStatusId = (int)PaymentStatusEnum.Completed;
            payment.PaymentDate = DateTime.UtcNow;
            payment.UpdatedAt = DateTime.UtcNow;

            entity.PaymentStatusId = (int)PaymentStatusEnum.Completed;
        }

        private async Task VoidAuthorizedPaymentAsync(Booking entity, CancellationToken ct = default)
        {
            var payment = entity.Payments
                .FirstOrDefault(p => p.PaymentStatusId == (int)PaymentStatusEnum.Authorized);

            if (payment == null)
                return;

            if (payment.PaymentMethodId == (int)PaymentMethodEnum.Stripe)
            {
                if (!payment.PaymentIntentId.HasValue)
                    throw new BusinessException("Stripe payment intent is missing.");

                var paymentIntent = await _context.PaymentIntents
                    .FirstOrDefaultAsync(x => x.Id == payment.PaymentIntentId.Value, ct);

                if (paymentIntent == null)
                    throw new NotFoundException("Stripe payment intent not found.");

                var stripeService = new PaymentIntentService();

                var canceledIntent = await stripeService.CancelAsync(
                    paymentIntent.StripePaymentIntentId,
                    cancellationToken: ct);

                if (canceledIntent.Status != "canceled")
                    throw new BusinessException("Stripe payment authorization could not be cancelled.");
            }
            else if (payment.PaymentMethodId == (int)PaymentMethodEnum.PayPal)
            {
                if (string.IsNullOrWhiteSpace(payment.ProviderAuthorizationId))
                    throw new BusinessException("PayPal authorization id is missing.");

                var client = _httpClientFactory.CreateClient();

                var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes(
                    $"{_payPalClientId}:{_payPalSecret}"
                ));

                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Basic", auth);

                var tokenResponse = await client.PostAsync(
                    "https://api-m.sandbox.paypal.com/v1/oauth2/token",
                    new FormUrlEncodedContent(new[]
                    {
                new KeyValuePair<string, string>("grant_type", "client_credentials")
                    }),
                    ct);

                var tokenJson = await tokenResponse.Content.ReadAsStringAsync(ct);
                var tokenData = JObject.Parse(tokenJson);
                string accessToken = tokenData["access_token"]?.ToString();

                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", accessToken);

                var voidResponse = await client.PostAsync(
                    $"https://api-m.sandbox.paypal.com/v2/payments/authorizations/{payment.ProviderAuthorizationId}/void",
                    new StringContent("", Encoding.UTF8, "application/json"),
                    ct);

                if (!voidResponse.IsSuccessStatusCode)
                    throw new BusinessException("PayPal payment authorization could not be voided.");
            }
            else
            {
                throw new BusinessException("Unsupported payment method.");
            }

            payment.PaymentStatusId = (int)PaymentStatusEnum.Failed;
            payment.UpdatedAt = DateTime.UtcNow;

            entity.PaymentStatusId = (int)PaymentStatusEnum.Failed;
        }

        private async Task<BookingResponse> MapWithAuditAsync(Booking entity, CancellationToken ct = default)
        {
            var response = _mapper.Map<BookingResponse>(entity);

            response.IsPaid = entity.PaymentStatusId == (int)PaymentStatusEnum.Completed;

            var lastLog = await _context.BookingAuditLogs
                .Where(x => x.BookingId == entity.Id)
                .OrderByDescending(x => x.CreatedAt)
                .Include(x => x.Admin)
                .FirstOrDefaultAsync(ct);

            response.LastAction = lastLog?.Action;
            response.LastAdminName = lastLog?.Admin?.Username;
            response.LastActionAt = lastLog?.CreatedAt;

            return response;
        }

        private async Task<List<BookingResponse>> MapWithAuditListAsync(
    List<Booking> bookings,
    CancellationToken ct = default)
        {
            if (!bookings.Any())
                return new List<BookingResponse>();

            var bookingIds = bookings
                .Select(x => x.Id)
                .ToList();

            var auditLogs = await _context.BookingAuditLogs
                .Where(x => bookingIds.Contains(x.BookingId))
                .Include(x => x.Admin)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync(ct);

            var latestLogs = auditLogs
                .GroupBy(x => x.BookingId)
                .ToDictionary(
                    x => x.Key,
                    x => x.First()
                );

            var result = new List<BookingResponse>();

            foreach (var booking in bookings)
            {
                var response = _mapper.Map<BookingResponse>(booking);

                response.IsPaid =
                    booking.PaymentStatusId == (int)PaymentStatusEnum.Completed;

                if (latestLogs.TryGetValue(booking.Id, out var lastLog))
                {
                    response.LastAction = lastLog.Action;
                    response.LastAdminName = lastLog.Admin?.Username;
                    response.LastActionAt = lastLog.CreatedAt;
                }

                result.Add(response);
            }

            return result;
        }

        public override async Task<PagedResult<BookingResponse>> GetAsync(
    BookingSearchObject search,
    CancellationToken cancellationToken = default)
        {
            var query = _context.Bookings.AsQueryable();

            query = ApplyFilter(query, search);

            query = query
                .Include(b => b.Space)
                    .ThenInclude(s => s.Facility)
                .Include(b => b.Space)
                    .ThenInclude(s => s.Images)
                .Include(b => b.BookingStatus)
                .Include(b => b.User)
                .Include(b => b.PaymentStatus)
                .OrderBy(b => b.StartTime);

            var totalCount = await query.CountAsync(cancellationToken);

            var page = search.Page ?? 0;
            var pageSize = search.PageSize ?? BaseSearchObject.DefaultPageSize;

            if (page < 0)
                page = 0;

            if (pageSize <= 0)
                pageSize = BaseSearchObject.DefaultPageSize;

            if (pageSize > BaseSearchObject.MaxPageSize)
                pageSize = BaseSearchObject.MaxPageSize;

            query = query
                .Skip(page * pageSize)
                .Take(pageSize);

            var list = await query.ToListAsync(cancellationToken);

            var items = await MapWithAuditListAsync(list, cancellationToken);

            return new PagedResult<BookingResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }


        public async Task SendReminderAsync(
       int bookingId,
       CancellationToken ct = default)
        {
            var booking = await _context.Bookings
                .Include(b => b.Space)
                .FirstOrDefaultAsync(b => b.Id == bookingId, ct);

            if (booking == null)
                throw new NotFoundException("Booking not found");

            var message = new BookingReminderMessage
            {
                UserId = booking.UserId,
                SpaceName = booking.Space.Name,
                StartTime = booking.StartTime,
                RelatedBookingId = booking.Id
            };

            await _rabbitMq.PublishAsync(
                message,
                "meetspace.booking-reminder");
        }

        public async Task<TicketValidationResponse> ValidateTicketAsync(string qrData, CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(qrData))
            {
                return InvalidTicket("QR ticket data is empty.");
            }

            int bookingId;

            try
            {
                using var document = JsonDocument.Parse(qrData);

                if (!document.RootElement.TryGetProperty("bookingId", out var bookingIdElement) ||
                    !bookingIdElement.TryGetInt32(out bookingId) ||
                    bookingId <= 0)
                {
                    return InvalidTicket("QR ticket does not contain a valid booking id.");
                }
            }
            catch
            {
                return InvalidTicket("QR ticket format is invalid.");
            }

            var booking = await _context.Bookings
                .Include(b => b.User)
                .Include(b => b.Space)
                    .ThenInclude(s => s.Facility)
                .Include(b => b.BookingStatus)
                .Include(b => b.PaymentStatus)
                .FirstOrDefaultAsync(b => b.Id == bookingId, ct);

            if (booking == null)
            {
                return InvalidTicket("Booking was not found.");
            }

            if (booking.BookingStatusId == (int)BookingStatusEnum.Cancelled)
            {
                return InvalidTicket("Ticket is not valid because the booking was cancelled.", booking);
            }

            if (booking.BookingStatusId == (int)BookingStatusEnum.Rejected)
            {
                return InvalidTicket("Ticket is not valid because the booking was rejected.", booking);
            }

            if (booking.BookingStatusId != (int)BookingStatusEnum.Approved)
            {
                return InvalidTicket("Ticket is not valid because the booking has not been approved yet.", booking);
            }

            if (booking.PaymentStatusId != (int)PaymentStatusEnum.Completed)
            {
                return InvalidTicket("Ticket is not valid because payment is not completed.", booking);
            }

            if (booking.EndTime < DateTime.Now)
            {
                return InvalidTicket("Ticket is not valid because the booking time has passed.", booking);
            }

            return new TicketValidationResponse
            {
                IsValid = true,
                Message = "Ticket is valid.",
                BookingId = booking.Id,
                Username = booking.User.Username,
                UserFullName = $"{booking.User.FirstName} {booking.User.LastName}",
                SpaceName = booking.Space.Name,
                FacilityAddress = booking.Space.Facility.Address,
                BookingStatus = booking.BookingStatus.Name,
                PaymentStatus = booking.PaymentStatus.Name,
                StartTime = booking.StartTime,
                EndTime = booking.EndTime
            };
        }

        private TicketValidationResponse InvalidTicket(string message, Booking? booking = null)
        {
            return new TicketValidationResponse
            {
                IsValid = false,
                Message = message,
                BookingId = booking?.Id,
                Username = booking?.User?.Username,
                UserFullName = booking?.User == null ? null : $"{booking.User.FirstName} {booking.User.LastName}",
                SpaceName = booking?.Space?.Name,
                FacilityAddress = booking?.Space?.Facility?.Address,
                BookingStatus = booking?.BookingStatus?.Name,
                PaymentStatus = booking?.PaymentStatus?.Name,
                StartTime = booking?.StartTime,
                EndTime = booking?.EndTime
            };
        }
    }
}
