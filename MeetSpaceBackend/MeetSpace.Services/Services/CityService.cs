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
    public class CityService
        : CachedReferenceCRUDService<
            CityResponse,
            CitySearchObject,
            City,
            CityInsertRequest,
            CityUpdateRequest>,
        ICityService
    {
        public CityService(
            MeetSpaceDbContext context,
            IMapper mapper,
            IMemoryCache cache)
            : base(context, mapper, cache)
        {
        }

        protected override IQueryable<City> ApplyFilter(
            IQueryable<City> query,
            CitySearchObject search)
        {
            query = query
                .Include(x => x.Country);

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x =>
                    x.Name.Contains(search.Name));
            }

            if (search.CountryId.HasValue)
            {
                query = query.Where(x =>
                    x.CountryId == search.CountryId.Value);
            }

            return query
                .OrderBy(x => x.Name);
        }
    }
}