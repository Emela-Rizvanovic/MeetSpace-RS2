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
    public class SpaceTypeService
      : CachedReferenceCRUDService<SpaceTypeResponse, SpaceTypeSearchObject, SpaceType, SpaceTypeInsertRequest, SpaceTypeUpdateRequest>,
        ISpaceTypeService
    {
        public SpaceTypeService(MeetSpaceDbContext context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper, cache)
        {
        }

        protected override IQueryable<SpaceType> ApplyFilter(IQueryable<SpaceType> query, SpaceTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return query;
        }

    }
}
