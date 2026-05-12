using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace MeetSpace.Services.Services
{
    public class FacilityService : BaseCRUDService<FacilityResponse, FacilitySearchObject, Facility, FacilityInsertRequest, FacilityUpdateRequest>, IFacilityService
    {
        public FacilityService(MeetSpaceDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        // ApplyFilter za pretragu po poljima FacilitySearchObject
        protected override IQueryable<Facility> ApplyFilter(IQueryable<Facility> query, FacilitySearchObject search)
        {
            query = query
        .Include(f => f.City)
        .ThenInclude(c => c.Country);

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(f => f.Name.Contains(search.Name));
            }

            if (!string.IsNullOrWhiteSpace(search.Address))
            {
                query = query.Where(f => f.Address.Contains(search.Address));
            }

            if (search.CityId.HasValue)
            {
                query = query.Where(f => f.CityId == search.CityId.Value);
            }

            if (search.CountryID.HasValue)
            {
                query = query.Where(f =>
                    f.City.CountryId ==
                    search.CountryID.Value);
            }

            return query;
        }

        protected override async Task BeforeUpdate(Facility entity, FacilityUpdateRequest request, CancellationToken cancellationToken = default)
        {
            entity.UpdatedAt = DateTime.UtcNow;
            await base.BeforeUpdate(entity, request, cancellationToken);
        }
    }
}
