using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Services
{
    public class BookingService : BaseCRUDService<BookingResponse, BookingSearchObject, Booking, BookingInsertRequest, BookingUpdateRequest>, IBookingService
    {
        public BookingService(MeetSpaceDbContext context, IMapper mapper)
            : base(context, mapper)
        {
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

            return query
                .Include(b => b.Space)
                    .ThenInclude(s => s.Facility)
                .Include(b => b.BookingStatus);
        }

        protected override async Task BeforeInsert(
    Booking entity,
    BookingInsertRequest request,
    CancellationToken cancellationToken = default)
        {
            entity.CreatedAt = DateTime.UtcNow;

            if (request.EndTime <= request.StartTime)
                throw new Exception("EndTime must be greater than StartTime.");

            // 1️⃣ Space
            var space = await _context.Spaces
                .FirstOrDefaultAsync(s => s.Id == request.SpaceId, cancellationToken);

            if (space == null)
                throw new Exception("Space not found.");

            // 2️⃣ Duration
            var hours = (decimal)(request.EndTime - request.StartTime).TotalHours;

            if (hours <= 0)
                throw new Exception("Invalid booking duration.");

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
                        throw new Exception($"Amenity {item.AmenityId} not found.");

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

            await base.BeforeInsert(entity, request, cancellationToken);
        }

        protected override async Task BeforeUpdate(Booking entity, BookingUpdateRequest request, CancellationToken cancellationToken = default)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            // Ako mijenjaš vrijeme / space, recalculiraj
            var start = request.StartTime ?? entity.StartTime;
            var end = request.EndTime ?? entity.EndTime;

            if (end <= start)
                throw new Exception("EndTime must be greater than StartTime.");

            var spaceId = request.SpaceId ?? entity.SpaceId;

            var space = await _context.Spaces.FirstOrDefaultAsync(s => s.Id == spaceId, cancellationToken);
            if (space == null)
                throw new Exception("Space not found.");

            var hours = (decimal)(end - start).TotalHours;
            if (hours <= 0)
                throw new Exception("Invalid booking duration.");

            entity.TotalPrice = Math.Round(hours * space.PricePerHour, 2);

            await base.BeforeUpdate(entity, request, cancellationToken);
        }

        public override async Task<BookingResponse> CreateAsync(BookingInsertRequest request, CancellationToken cancellationToken = default)
        {
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
                .Include(b => b.BookingStatus)
                .FirstAsync(b => b.Id == entity.Id, cancellationToken);

            return MapToResponse(loaded);
        }


        public override async Task<BookingResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Bookings
                .Include(b => b.Space).ThenInclude(s => s.Facility)
                .Include(b => b.BookingStatus)
                .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);

            return entity == null ? null : MapToResponse(entity);
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
                .Include(b => b.BookingStatus)
                .FirstAsync(b => b.Id == id, cancellationToken);

            return MapToResponse(loaded);
        }


        public async Task<List<BookingResponse>> GetByUserIdAsync(int userId, CancellationToken ct = default)
        {
            var list = await _context.Bookings
                .Include(b => b.Space).ThenInclude(s => s.Facility)
                .Include(b => b.BookingStatus)
                .Where(b => b.UserId == userId)
                .OrderByDescending(b => b.StartTime)
                .ToListAsync(ct);

            return list.Select(MapToResponse).ToList();
        }

        public async Task<List<BookingResponse>> GetBySpaceIdAsync(int spaceId, CancellationToken ct = default)
        {
            var list = await _context.Bookings
                .Include(b => b.Space)
                    .ThenInclude(s => s.Facility)
                .Include(b => b.BookingStatus)
                .Where(b => b.SpaceId == spaceId)
                .OrderBy(b => b.StartTime)
                .ToListAsync(ct);

            return list.Select(MapToResponse).ToList();
        }
    }
}
