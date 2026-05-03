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

            if (search.FacilityId.HasValue)
                query = query.Where(s => s.FacilityId == search.FacilityId.Value);

            if (search.SpaceTypeId.HasValue)
                query = query.Where(s => s.SpaceTypeId == search.SpaceTypeId.Value);

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
            var entity = _mapper.Map<Space>(request);
            entity.CreatedAt = DateTime.UtcNow;

            await _context.Spaces.AddAsync(entity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);

            // ✅ 1) Upload images (existing logic)
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

            // ✅ 2) Save amenities (NEW)
            if (request.AmenityIds != null && request.AmenityIds.Any())
            {
                var distinctIds = request.AmenityIds.Distinct().ToList();

                // (optional) validate IDs exist to avoid FK errors
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

            // ✅ Reload with all includes so response has Images + Facility + Amenities
            entity = await _context.Spaces
                .Include(s => s.Images)
                .Include(s => s.Facility)
                .Include(s => s.SpaceAmenities).ThenInclude(sa => sa.Amenity)
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .FirstAsync(s => s.Id == entity.Id, cancellationToken);

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
                .Include(s => s.SpaceAmenities) // ✅ needed for replace
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

            if (entity == null)
                return null;

            // Update fields (existing logic)
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

            // ✅ 1) Delete images (existing logic)
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

            // ✅ 2) Add new images (existing logic)
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

            // ✅ 3) Replace amenities (NEW) — only if AmenityIds provided
            // AMENITIES: diraj samo ako su poslani neki ID-evi
            if (request.AmenityIds != null && request.AmenityIds.Count > 0)
            {
                var newIdsDistinct = request.AmenityIds.Distinct().ToList();

                // (opcionalno) validacija da amenity postoji
                var validIds = await _context.Amenities
                    .Where(a => newIdsDistinct.Contains(a.Id))
                    .Select(a => a.Id)
                    .ToListAsync(cancellationToken);

                // replace
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

            // ✅ Reload with all includes so response has Images + Facility + Amenities
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
                .Include(s => s.SpaceAmenities) // ✅ clean links too
                .Include(s => s.Reviews)
                .Include(s => s.SpaceType)
                .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

            if (entity == null)
                return false;

            // delete images from blob + db
            foreach (var img in entity.Images)
            {
                await _blobService.DeleteSpaceImageAsync(img.ImageUrl);
                _context.SpaceImages.Remove(img);
            }

            // remove amenities links
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

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync(cancellationToken);

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                    query = query.Skip(search.Page.Value * (search.PageSize ?? 20));

                if (search.PageSize.HasValue)
                    query = query.Take(search.PageSize.Value);
            }

            var entities = await query.ToListAsync(cancellationToken);
            var mapped = entities.Select(MapToResponse).ToList();

            return await base.GetAsync(search, cancellationToken);
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
                .FirstOrDefaultAsync(s => s.Id == spaceId);

            if (space == null)
                throw new Exception("Space not found.");

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
