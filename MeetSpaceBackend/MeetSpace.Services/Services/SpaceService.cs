using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using MeetSpace.Models.Exceptions;

namespace MeetSpace.Services.Services
{
    public class SpaceService
        : BaseCRUDService<SpaceResponse, SpaceSearchObject, Space, SpaceInsertRequest, SpaceUpdateRequest>,
          ISpaceService
    {
        private readonly IBlobService _blobService;

        public SpaceService(MeetSpaceDbContext context, IMapper mapper, IBlobService blobService)
            : base(context, mapper)
        {
            _blobService = blobService;
        }

        protected override IQueryable<Space> ApplyFilter(IQueryable<Space> query, SpaceSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(s => s.Name.Contains(search.Name));

            if (search.IsActive.HasValue)
                query = query.Where(s => s.IsActive == search.IsActive.Value);
            else
                query = query.Where(s => s.IsActive);

            if (search.FacilityId.HasValue)
                query = query.Where(s => s.FacilityId == search.FacilityId.Value);

            if (search.SpaceTypeId.HasValue)
                query = query.Where(s => s.SpaceTypeId == search.SpaceTypeId.Value);

            if (search.MinPrice.HasValue)
                query = query.Where(s =>
                    s.PricePerHour >= search.MinPrice.Value);

            if (search.MaxPrice.HasValue)
                query = query.Where(s =>
                    s.PricePerHour <= search.MaxPrice.Value);

            if (search.MinCapacity.HasValue)
                query = query.Where(s =>
                    s.Capacity >= search.MinCapacity.Value);

            if (search.MaxCapacity.HasValue)
                query = query.Where(s =>
                    s.Capacity <= search.MaxCapacity.Value);

            return query;
        }

        protected override async Task BeforeUpdate(
            Space entity,
            SpaceUpdateRequest request,
            CancellationToken cancellationToken = default
        )
        {
            entity.UpdatedAt = DateTime.UtcNow;
            await base.BeforeUpdate(entity, request, cancellationToken);
        }

        public override async Task<SpaceResponse> CreateAsync(
            SpaceInsertRequest request,
            CancellationToken cancellationToken = default
        )
        {
            await using var transaction =
    await _context.Database.BeginTransactionAsync(cancellationToken);

            var entity = _mapper.Map<Space>(request);
            entity.CreatedAt = DateTime.UtcNow;

            await _context.Spaces.AddAsync(entity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);

            if (request.Images != null && request.Images.Any())
            {
                foreach (var file in request.Images)
                {
                    string url = await _blobService.UploadSpaceImageAsync(file);

                    var img = new SpaceImage
                    {
                        SpaceId = entity.Id,
                        ImageUrl = url
                    };

                    await _context.SpaceImages.AddAsync(img, cancellationToken);
                }

                await _context.SaveChangesAsync(cancellationToken);
            }

            if (request.AmenityIds != null && request.AmenityIds.Any())
            {
                var distinctIds = request.AmenityIds.Distinct().ToList();

                var existingAmenityIds = await _context.Amenities
                    .Where(a => distinctIds.Contains(a.Id))
                    .Select(a => a.Id)
                    .ToListAsync(cancellationToken);

                foreach (var amenityId in existingAmenityIds)
                {
                    await _context.SpaceAmenities.AddAsync(new SpaceAmenity
                    {
                        SpaceId = entity.Id,
                        AmenityId = amenityId
                    }, cancellationToken);
                }

                await _context.SaveChangesAsync(cancellationToken);
            }

            entity = await _context.Spaces
                .Include(s => s.Images)
                .Include(s => s.Facility)
                .Include(s => s.SpaceAmenities).ThenInclude(sa => sa.Amenity)
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .FirstAsync(s => s.Id == entity.Id, cancellationToken);

            await transaction.CommitAsync(cancellationToken);

            return _mapper.Map<SpaceResponse>(entity);
        }

        public override async Task<SpaceResponse?> UpdateAsync(
            int id,
            SpaceUpdateRequest request,
            CancellationToken cancellationToken = default
        )
        {
            var entity = await _context.Spaces
                .Include(s => s.Images)
                .Include(s => s.SpaceAmenities) 
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

            if (entity == null)
                return null;

            if (!string.IsNullOrWhiteSpace(request.Name))
                entity.Name = request.Name;

            if (!string.IsNullOrWhiteSpace(request.Description))
                entity.Description = request.Description;

            if (request.PricePerHour.HasValue)
                entity.PricePerHour = request.PricePerHour.Value;

            if (request.Capacity.HasValue)
                entity.Capacity = request.Capacity.Value;

            if (request.FacilityId.HasValue)
                entity.FacilityId = request.FacilityId.Value;

            if (request.SpaceTypeId.HasValue)
                entity.SpaceTypeId = request.SpaceTypeId.Value;

            entity.UpdatedAt = DateTime.UtcNow;

            if (request.DeleteImageIds != null && request.DeleteImageIds.Any())
            {
                foreach (var idToDelete in request.DeleteImageIds)
                {
                    var img = entity.Images.FirstOrDefault(i => i.Id == idToDelete);
                    if (img != null)
                    {
                        await _blobService.DeleteSpaceImageAsync(img.ImageUrl);
                        _context.SpaceImages.Remove(img);
                    }
                }
            }

            if (request.NewImages != null && request.NewImages.Any())
            {
                foreach (var file in request.NewImages)
                {
                    string url = await _blobService.UploadSpaceImageAsync(file);

                    var newImg = new SpaceImage
                    {
                        SpaceId = entity.Id,
                        ImageUrl = url
                    };

                    await _context.SpaceImages.AddAsync(newImg, cancellationToken);
                }
            }

            if (request.ReplaceAmenities || request.AmenityIds != null)
            {
                var newIdsDistinct = (request.AmenityIds ?? new List<int>())
    .Distinct()
    .ToList();

                var validIds = await _context.Amenities
                    .Where(a => newIdsDistinct.Contains(a.Id))
                    .Select(a => a.Id)
                    .ToListAsync(cancellationToken);

                var invalidIds = newIdsDistinct
                    .Except(validIds)
                    .ToList();

                if (invalidIds.Any())
                {
                    throw new BusinessException(
                        $"Invalid amenity IDs: {string.Join(", ", invalidIds)}."
                    );
                }

                _context.SpaceAmenities.RemoveRange(entity.SpaceAmenities);

                foreach (var amenityId in validIds)
                {
                    entity.SpaceAmenities.Add(new SpaceAmenity
                    {
                        SpaceId = entity.Id,
                        AmenityId = amenityId
                    });
                }
            }



            await _context.SaveChangesAsync(cancellationToken);

            entity = await _context.Spaces
                .Include(s => s.Images)
                .Include(s => s.Facility)
                .Include(s => s.SpaceAmenities).ThenInclude(sa => sa.Amenity)
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .FirstAsync(s => s.Id == id, cancellationToken);

            return _mapper.Map<SpaceResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Spaces
                .Include(s => s.Images)
                .Include(s => s.SpaceAmenities)
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

            if (entity == null)
                return false;

            var hasBookings = await _context.Bookings
    .AnyAsync(b => b.SpaceId == id, cancellationToken);

            if (hasBookings)
            {
                entity.IsActive = false;
                entity.ArchivedAt = DateTime.UtcNow;
                entity.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync(cancellationToken);
                return true;
            }

            foreach (var img in entity.Images)
            {
                await _blobService.DeleteSpaceImageAsync(img.ImageUrl);
                _context.SpaceImages.Remove(img);
            }

            _context.SpaceAmenities.RemoveRange(entity.SpaceAmenities);

            _context.Spaces.Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);

            return true;
        }

        public override async Task<PagedResult<SpaceResponse>> GetAsync(
            SpaceSearchObject search,
            CancellationToken cancellationToken = default
        )
        {
            var query = _context.Spaces
                .Include(s => s.Images)
                .Include(s => s.Facility)
                .Include(s => s.SpaceAmenities).ThenInclude(sa => sa.Amenity)
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .AsQueryable();

            query = ApplyFilter(query, search);
            query = ApplySort(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync(cancellationToken);

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

            var entities = await query.ToListAsync(cancellationToken);
            var mapped = entities.Select(MapToResponse).ToList();

            return new PagedResult<SpaceResponse>
            {
                Items = mapped,
                TotalCount = totalCount ?? mapped.Count,
                Page = page,
                PageSize = pageSize
            };
        }

        public override async Task<SpaceResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Spaces
                .Include(s => s.Images)
                .Include(s => s.Facility)
                .Include(s => s.SpaceAmenities).ThenInclude(sa => sa.Amenity)
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

            return entity == null ? null : MapToResponse(entity);
        }

        public async Task<List<SpaceImageResponse>> AddImagesAsync(int spaceId, List<IFormFile> files)
        {
            var space = await _context.Spaces
    .Include(s => s.Images)
    .FirstOrDefaultAsync(s => s.Id == spaceId && s.IsActive);

            if (space == null)
                throw new NotFoundException("Space not found.");

            var newImages = new List<SpaceImage>();

            foreach (var file in files)
            {
                string url = await _blobService.UploadSpaceImageAsync(file);

                var image = new SpaceImage
                {
                    SpaceId = spaceId,
                    ImageUrl = url
                };

                newImages.Add(image);
                await _context.SpaceImages.AddAsync(image);
            }

            await _context.SaveChangesAsync();

            return newImages
                .Select(i => _mapper.Map<SpaceImageResponse>(i))
                .ToList();
        }
    }
}
