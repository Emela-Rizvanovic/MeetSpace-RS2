using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace MeetSpace.Services.Services
{
    public class BookingStatusService
        : CachedReferenceCRUDService<BookingStatusResponse, BookingStatusSearchObject, BookingStatus, BookingStatusInsertRequest, BookingStatusUpdateRequest>,
          IBookingStatusService
    {
        public BookingStatusService(MeetSpaceDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper, cache)
        {
        }

        protected override IQueryable<BookingStatus> ApplyFilter(IQueryable<BookingStatus> query, BookingStatusSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(x => x.Name.Contains(search.Name));

            return query;
        }

        protected override async Task BeforeInsert(BookingStatus entity, BookingStatusInsertRequest request, CancellationToken cancellationToken = default)
        {
            var exists = await _context.BookingStatuses.AnyAsync(x => x.Name.ToLower() == request.Name.ToLower(), cancellationToken);
            if (exists)
                throw new ArgumentException("Booking status with this name already exists.");

            await base.BeforeInsert(entity, request, cancellationToken);
        }

        protected override async Task BeforeUpdate(BookingStatus entity, BookingStatusUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var exists = await _context.BookingStatuses.AnyAsync(
                x => x.Id != entity.Id && x.Name.ToLower() == request.Name.ToLower(),
                cancellationToken);

            if (exists)
                throw new ArgumentException("Booking status with this name already exists.");

            await base.BeforeUpdate(entity, request, cancellationToken);
        }
    }
}
