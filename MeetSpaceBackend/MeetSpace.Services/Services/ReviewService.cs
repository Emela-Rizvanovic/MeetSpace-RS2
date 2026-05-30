using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using MeetSpace.Models.Exceptions;
using MeetSpace.Models.Enums;

namespace MeetSpace.Services.Services
{
    public class ReviewService
        : BaseCRUDService<ReviewResponse, ReviewSearchObject, Review, ReviewInsertRequest, ReviewUpdateRequest>,
          IReviewService
    {
        public ReviewService(MeetSpaceDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            query = query
    .Include(r => r.User)
    .Include(r => r.Space);

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(r =>
                    r.User.FirstName.Contains(search.Name) ||
                    r.User.LastName.Contains(search.Name) ||
                    r.Space.Name.Contains(search.Name)
                );
            }

            if (search.SpaceId.HasValue)
                query = query.Where(r => r.SpaceId == search.SpaceId.Value);

            if (search.UserId.HasValue)
                query = query.Where(r => r.UserId == search.UserId.Value);

            if (search.MinRating.HasValue)
                query = query.Where(r => r.Rating >= search.MinRating.Value);

            if (search.MaxRating.HasValue)
                query = query.Where(r => r.Rating <= search.MaxRating.Value);

            if (search.CreatedFrom.HasValue)
                query = query.Where(r => r.CreatedAt >= search.CreatedFrom.Value);

            if (search.CreatedTo.HasValue)
                query = query.Where(r => r.CreatedAt <= search.CreatedTo.Value);

            if (search.SortByNewest == true)
                query = query.OrderByDescending(r => r.CreatedAt);
            else
                query = query.OrderByDescending(r => r.CreatedAt);

            return query
                .Include(r => r.User)
                .Include(r => r.Space);
        }

        protected override async Task BeforeInsert(
            Review entity,
            ReviewInsertRequest request,
            CancellationToken cancellationToken = default)
        {
            entity.CreatedAt = DateTime.UtcNow;

            if (request.Rating < 1 || request.Rating > 5)
                throw new BusinessException("Rating must be between 1 and 5.");

            var spaceExists = await _context.Spaces
                .AnyAsync(s => s.Id == request.SpaceId, cancellationToken);

            if (!spaceExists)
                throw new NotFoundException("Space not found.");

            var now = DateTime.UtcNow;

            var hasCompletedBooking = await _context.Bookings
    .AnyAsync(b =>
        b.UserId == entity.UserId &&
        b.SpaceId == request.SpaceId &&
        b.BookingStatusId == (int)BookingStatusEnum.Approved &&
        b.EndTime <= now,
        cancellationToken);

            if (!hasCompletedBooking)
            {
                throw new BusinessException(
                    "You can leave a review only for visited spaces after your booking has finished.");
            }

            var exists = await _context.Reviews
                .AnyAsync(r => r.UserId == entity.UserId &&
                               r.SpaceId == request.SpaceId,
                               cancellationToken);

            if (exists)
                throw new BusinessException("Review already exists.");

            await base.BeforeInsert(entity, request, cancellationToken);
        }

        protected override async Task BeforeUpdate(
            Review entity,
            ReviewUpdateRequest request,
            CancellationToken cancellationToken = default)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            if (request.Rating < 1 || request.Rating > 5)
                throw new BusinessException("Rating must be between 1 and 5.");

            await base.BeforeUpdate(entity, request, cancellationToken);
        }

        public override async Task<ReviewResponse?> GetByIdAsync(
            int id,
            CancellationToken cancellationToken = default)
        {
            var entity = await _context.Reviews
                .Include(r => r.User)
                .Include(r => r.Space)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            return entity == null ? null : MapToResponse(entity);
        }

        public override async Task<ReviewResponse> CreateAsync(
    ReviewInsertRequest request,
    CancellationToken cancellationToken = default)
        {
            var entity = new Review();

            MapInsertToEntity(entity, request);

            entity.UserId = request.UserId; 

            await BeforeInsert(entity, request, cancellationToken);

            _context.Reviews.Add(entity);
            await _context.SaveChangesAsync(cancellationToken);

            return MapToResponse(entity);
        }


        public async Task<double> GetAverageRatingAsync(int spaceId)
        {
            return await _context.Reviews
                .Where(r => r.SpaceId == spaceId)
                .AverageAsync(r => (double?)r.Rating) ?? 0;
        }

        public async Task<int> GetReviewCountAsync(int spaceId)
        {
            return await _context.Reviews
                .CountAsync(r => r.SpaceId == spaceId);
        }

        public async Task<ReviewSummaryResponse> GetSummaryAsync(int spaceId)
        {
            var summary = await _context.Reviews
                .Where(r => r.SpaceId == spaceId)
                .GroupBy(r => r.SpaceId)
                .Select(g => new ReviewSummaryResponse
                {
                    AverageRating = Math.Round(g.Average(r => r.Rating), 2),
                    TotalReviews = g.Count()
                })
                .FirstOrDefaultAsync();

            return summary ?? new ReviewSummaryResponse
            {
                AverageRating = 0,
                TotalReviews = 0
            };
        }
    }
}