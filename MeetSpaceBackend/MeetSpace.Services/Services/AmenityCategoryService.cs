using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.Extensions.Caching.Memory;

namespace MeetSpace.Services.Services
{
    public class AmenityCategoryService 
        : CachedReferenceCRUDService<AmenityCategoryResponse, AmenityCategorySearchObject, AmenityCategory, AmenityCategoryInsertRequest, AmenityCategoryUpdateRequest>,
        IAmenityCategoryService
    {
        public AmenityCategoryService(MeetSpaceDbContext context, IMapper mapper, IMemoryCache cache) 
            : base (context, mapper, cache)
        { 
        }

        protected override IQueryable<AmenityCategory> ApplyFilter(IQueryable<AmenityCategory> query, AmenityCategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return query;
        }

    }
}
