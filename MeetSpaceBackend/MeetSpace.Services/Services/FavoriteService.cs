using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using MeetSpace.Models.Exceptions;

namespace MeetSpace.Services.Services
{
    public class FavoriteService : IFavoriteService
    {
        private readonly MeetSpaceDbContext _context;

        public FavoriteService(MeetSpaceDbContext context)
        {
            _context = context;
        }

        public async Task AddAsync(FavoriteInsertRequest request)
        {
            if (!request.UserId.HasValue || request.UserId.Value <= 0)
                throw new BusinessException("User is required.");

            var exists = await _context.Favorites
                .AnyAsync(f => f.UserId == request.UserId.Value && f.SpaceId == request.SpaceId);

            if (exists)
                return;

            var favorite = new Favorite
            {
                UserId = request.UserId.Value,
                SpaceId = request.SpaceId
            };

            _context.Favorites.Add(favorite);
            await _context.SaveChangesAsync();
        }

        public async Task RemoveAsync(int userId, int spaceId)
        {
            var favorite = await _context.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.SpaceId == spaceId);

            if (favorite == null)
                return;

            _context.Favorites.Remove(favorite);
            await _context.SaveChangesAsync();
        }

        public async Task<List<SpaceResponse>> GetByUserAsync(int userId)
        {
            return await _context.Favorites
                .Where(f => f.UserId == userId && f.Space != null && f.Space.IsActive)
                .Include(f => f.Space)
                            .ThenInclude(s => s.Images)
                .Include(f => f.Space)
                    .ThenInclude(s => s.SpaceAmenities)
                .Include(f => f.Space)
                    .ThenInclude(s => s.Facility)
                .Include(f => f.Space)
                    .ThenInclude(s => s.Reviews)   
                .Select(f => new SpaceResponse
                {
                    Id = f.Space.Id,
                    Name = f.Space.Name,
                    Description = f.Space.Description,
                    PricePerHour = f.Space.PricePerHour,
                    Capacity = f.Space.Capacity,
                    FacilityId = f.Space.FacilityId,
                    FacilityName = f.Space.Facility.Name,
                    FacilityAddress = f.Space.Facility.Address,
                    SpaceTypeId = f.Space.SpaceTypeId,
                    IsActive = f.Space.IsActive,
                    ArchivedAt = f.Space.ArchivedAt,
                    CreatedAt = f.Space.CreatedAt,
                    UpdatedAt = f.Space.UpdatedAt,

                    AverageRating = f.Space.Reviews.Any()
                        ? f.Space.Reviews.Average(r => r.Rating)
                        : 0,

                    TotalReviews = f.Space.Reviews.Count(),

                    Images = f.Space.Images
                        .Select(img => new SpaceImageResponse
                        {
                            Id = img.Id,
                            ImageUrl = img.ImageUrl
                        }).ToList(),

                    Amenities = f.Space.SpaceAmenities
    .Where(a => a.Amenity != null)
    .Select(a => new AmenityResponse
    {
        Id = a.Amenity.Id,
        Name = a.Amenity.Name,
        Description = a.Amenity.Description,
        Price = a.Amenity.Price,
        AmenityCategoryId = a.Amenity.AmenityCategoryId,
        CreatedAt = a.Amenity.CreatedAt,
        UpdatedAt = a.Amenity.UpdatedAt
    }).ToList()
                })
                .ToListAsync();
        }
    }

}
