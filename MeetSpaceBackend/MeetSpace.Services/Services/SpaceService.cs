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
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Services
{
    public class SpaceService : BaseCRUDService<SpaceResponse, SpaceSearchObject, Space, SpaceInsertRequest, SpaceUpdateRequest>, ISpaceService
    {
        private readonly IBlobService _blobService;
        public SpaceService(MeetSpaceDbContext context, IMapper mapper, IBlobService blobService)
            : base(context, mapper)
        {
            _blobService = blobService;
        }

        // ApplyFilter za pretragu po poljima SpaceSearchObject
        protected override IQueryable<Space> ApplyFilter(IQueryable<Space> query, SpaceSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(s => s.Name.Contains(search.Name));
            }

            if (search.FacilityId.HasValue)
            {
                query = query.Where(s => s.FacilityId == search.FacilityId.Value);
            }

            if (search.SpaceTypeId.HasValue)
            {
                query = query.Where(s => s.SpaceTypeId == search.SpaceTypeId.Value);
            }

            return query;
        }

        protected override async Task BeforeUpdate(Space entity, SpaceUpdateRequest request, CancellationToken cancellationToken = default)
        {
            entity.UpdatedAt = DateTime.UtcNow;
            await base.BeforeUpdate(entity, request, cancellationToken);
        }

        public override async Task<SpaceResponse> CreateAsync(SpaceInsertRequest request, CancellationToken cancellationToken = default)
        {
            var entity = _mapper.Map<Space>(request);
            entity.CreatedAt = DateTime.UtcNow;

            await _context.Spaces.AddAsync(entity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);

            // Upload slika ako postoje
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

                await _context.SaveChangesAsync();
            }

            entity = await _context.Spaces.Include(s => s.Images).FirstAsync(s => s.Id == entity.Id);

            return _mapper.Map<SpaceResponse>(entity);
        }

        public override async Task<SpaceResponse?> UpdateAsync(int id, SpaceUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Spaces
                .Include(s => s.Images)
                .FirstOrDefaultAsync(s => s.Id == id, cancellationToken);

            if (entity == null)
                return null;

            // Update polja
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

            // 1) Brisanje slika
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

            // 2) Dodavanje novih slika
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

                    await _context.SpaceImages.AddAsync(newImg);
                }
            }

            await _context.SaveChangesAsync(cancellationToken);

            entity = await _context.Spaces.Include(s => s.Images).FirstAsync(s => s.Id == id);

            return _mapper.Map<SpaceResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Spaces
                .Include(s => s.Images)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (entity == null)
                return false;

            // Brisanje slika iz Azure Blob + baze
            foreach (var img in entity.Images)
            {
                await _blobService.DeleteSpaceImageAsync(img.ImageUrl);
                _context.SpaceImages.Remove(img);
            }

            _context.Spaces.Remove(entity);
            await _context.SaveChangesAsync();

            return true;
        }

        public override async Task<PagedResult<SpaceResponse>> GetAsync(SpaceSearchObject search, CancellationToken cancellationToken = default)
        {
            var query = _context.Spaces
                .Include(s => s.Images) // dohvatanje slika
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

            return new PagedResult<SpaceResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<SpaceResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Spaces
                .Include(s => s.Images) // <-- uključuje slike
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



        // TO-DO 
        // dodati ako bude trebalo u buducnosti Task BeforeUpdate, BeforeInsert, DeleteAsync
    }
}
