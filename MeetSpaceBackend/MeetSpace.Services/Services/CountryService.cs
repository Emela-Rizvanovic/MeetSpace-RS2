using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;

namespace MeetSpace.Services.Services
{
    public class CountryService
        : BaseCRUDService<
            CountryResponse,
            CountrySearchObject,
            Country,
            CountryInsertRequest,
            CountryUpdateRequest>,
        ICountryService
    {
        public CountryService(
            MeetSpaceDbContext context,
            IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Country> ApplyFilter(
            IQueryable<Country> query,
            CountrySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x =>
                    x.Name.Contains(search.Name));
            }

            return query.OrderBy(x => x.Name);
        }
    }
}