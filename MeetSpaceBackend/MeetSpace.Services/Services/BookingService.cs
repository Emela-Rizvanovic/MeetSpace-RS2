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
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore.Storage;
using MeetSpace.Models.Exceptions;

namespace MeetSpace.Services.Services
{
    public class BookingService : BaseCRUDService<BookingResponse, BookingSearchObject, Booking, BookingInsertRequest, BookingUpdateRequest>, IBookingService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IRabbitMQService _rabbitMq;
        public BookingService(MeetSpaceDbContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IRabbitMQService rabbitMq)
            : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
            _rabbitMq = rabbitMq;
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

        protected override async Task BeforeInsert(
    Booking entity,
    BookingInsertRequest request,
    CancellationToken cancellationToken = default)
        {
            entity.CreatedAt = DateTime.UtcNow;

            if (request.EndTime <= request.StartTime)
                throw new BusinessException("EndTime must be greater than StartTime.");

            var hasConflict = await _context.Bookings
    .AnyAsync(b =>
        b.SpaceId == request.SpaceId &&
        b.BookingStatusId != (int)BookingStatusEnum.Rejected && // ignore rejected
        request.StartTime < b.EndTime &&
        request.EndTime > b.StartTime
    );

            if (hasConflict)
                throw new BusinessException("Time slot already booked.");

            // 1️⃣ Space
            var space = await _context.Spaces
                .FirstOrDefaultAsync(s => s.Id == request.SpaceId, cancellationToken);

            if (space == null)
                throw new NotFoundException("Space not found.");

            // 2️⃣ Duration
            var hours = (decimal)(request.EndTime - request.StartTime).TotalHours;

            if (hours <= 0)
                throw new BusinessException("Invalid booking duration.");

            var basePrice = Math.Round(hours * space.PricePerHour, 2);

            decimal amenitiesTotal = 0m;

            // 3️⃣ Amenities (NEW LOGIC)
            if (request.Amenities != null && request.Amenities.Any())
            {
                foreach (var item in request.Amenities)
                {
                    var amenity = await _context.Amenities
                        .FirstOrDefaultAsync(a => a.Id == item.AmenityId, cancellationToken);

                    if (amenity == null)
                        throw new NotFoundException($"Amenity {item.AmenityId} not found.");

                    var quantity = item.Quantity <= 0 ? 1 : item.Quantity;

                    var itemTotal = Math.Round(amenity.Price * quantity, 2);

                    entity.BookingAmenities.Add(new BookingAmenity
                    {
                        AmenityId = amenity.Id,
                        Quantity = quantity,
                        Price = amenity.Price // snapshot price
                    });

                    amenitiesTotal += itemTotal;
                }
            }

            // 4️⃣ Final total
            entity.TotalPrice = Math.Round(basePrice + amenitiesTotal, 2);

            entity.PaymentStatusId = (int)PaymentStatusEnum.Completed; // Completed
            entity.BookingStatusId = (int)BookingStatusEnum.Pending; // Pending approval

            await base.BeforeInsert(entity, request, cancellationToken);
        }

        protected override async Task BeforeUpdate(Booking entity, BookingUpdateRequest request, CancellationToken cancellationToken = default)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            var start = request.StartTime ?? entity.StartTime;
            var end = request.EndTime ?? entity.EndTime;

            if (end <= start)
                throw new BusinessException("EndTime must be greater than StartTime.");

            var spaceId = request.SpaceId ?? entity.SpaceId;

            var space = await _context.Spaces.FirstOrDefaultAsync(s => s.Id == spaceId, cancellationToken);
            if (space == null)
                throw new NotFoundException("Space not found.");

            var hours = (decimal)(end - start).TotalHours;
            if (hours <= 0)
                throw new BusinessException("Invalid booking duration.");

            entity.TotalPrice = Math.Round(hours * space.PricePerHour, 2);

            await base.BeforeUpdate(entity, request, cancellationToken);
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

            // update RecommendationLog ako je prostor bio preporučen

            var log = await _context.RecommendationLogs
                .Where(r => r.UserId == entity.UserId && r.SpaceId == entity.SpaceId)
                .OrderByDescending(r => r.RecommendedAt)
                .FirstOrDefaultAsync(cancellationToken);

            if (log != null)
            {
                log.Booked = true;
                await _context.SaveChangesAsync(cancellationToken);
            }

            // reload sa include-ovima da mapper dobije Space/Facility/Status
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

            return MapWithAudit(loaded);
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

            return entity == null ? null : MapWithAudit(entity);
        }

        public override async Task<BookingResponse?> UpdateAsync(int id, BookingUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Bookings
                .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);

            if (entity == null)
                return null;

            // ✅ ovdje recalculacija totalPrice + UpdatedAt
            await BeforeUpdate(entity, request, cancellationToken);

            await _context.SaveChangesAsync(cancellationToken);

            // ✅ reload sa include-ovima radi response-a
            var loaded = await _context.Bookings
                .Include(b => b.Space).ThenInclude(s => s.Facility)
                .Include(b => b.Space)
        .ThenInclude(s => s.Images)
                .Include(b => b.BookingStatus)
                .Include(b => b.User)
                .Include(b => b.PaymentStatus)
                .FirstAsync(b => b.Id == id, cancellationToken);

            return MapWithAudit(loaded);
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

            return list.Select(MapWithAudit).ToList();
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

            return list.Select(MapWithAudit).ToList();
        }

        public async Task ApproveAsync(int id, CancellationToken ct = default)
        {
            var entity = await _context.Bookings
    .Include(b => b.User)
    .Include(b => b.Space)
    .FirstOrDefaultAsync(b => b.Id == id, ct);

            if (entity == null)
                throw new NotFoundException("Booking not found");

            entity.BookingStatusId = (int)BookingStatusEnum.Approved; // Approved

            var userId = int.Parse(
                _httpContextAccessor.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier).Value
            );

            _context.BookingAuditLogs.Add(new BookingAuditLog
            {
                BookingId = entity.Id,
                AdminId = userId,
                Action = "Approved",
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync(ct);

            await _rabbitMq.PublishAsync(new BookingStatusChangedMessage
            {
                UserId = entity.UserId,
                SpaceName = entity.Space.Name,
                StartTime = entity.StartTime,
                IsApproved = true
            }, "meetspace.booking-status");
        }

        public async Task RejectAsync(int id, string reason, CancellationToken ct = default)
        {
            var entity = await _context.Bookings
    .Include(b => b.User)
    .Include(b => b.Space)
    .FirstOrDefaultAsync(b => b.Id == id, ct);

            if (entity == null)
                throw new NotFoundException("Booking not found");

            entity.BookingStatusId = (int)BookingStatusEnum.Rejected; //Rejected
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
                Reason = reason
            }, "meetspace.booking-status");
        }

        public async Task<bool> HasConflict(int spaceId, DateTime start, DateTime end, int? ignoreId = null)
        {
            return await _context.Bookings
                .AnyAsync(b =>
                    b.SpaceId == spaceId &&
                    b.BookingStatusId != (int)BookingStatusEnum.Rejected &&
                    (ignoreId == null || b.Id != ignoreId) &&
                    start < b.EndTime &&
                    end > b.StartTime
                );
        }

        private BookingResponse MapWithAudit(Booking entity)
        {
            var response = _mapper.Map<BookingResponse>(entity);

            var lastLog = _context.BookingAuditLogs
                .Where(x => x.BookingId == entity.Id)
                .OrderByDescending(x => x.CreatedAt)
                .Include(x => x.Admin)
                .FirstOrDefault();

            response.LastAction = lastLog?.Action;
            response.LastAdminName = lastLog?.Admin?.Username;
            response.LastActionAt = lastLog?.CreatedAt;

            return response;
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

            if (search.Page.HasValue && search.PageSize.HasValue)
            {
                query = query
                    .Skip(search.Page.Value * search.PageSize.Value)
                    .Take(search.PageSize.Value);
            }

            var list = await query.ToListAsync(cancellationToken);

            return new PagedResult<BookingResponse>
            {
                Items = list.Select(MapWithAudit).ToList(),
                TotalCount = totalCount,
                Page = search.Page ?? 0,
                PageSize = search.PageSize ?? 10
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
                StartTime = booking.StartTime
            };

            await _rabbitMq.PublishAsync(
                message,
                "meetspace.booking-reminder");
        }
    }
}
