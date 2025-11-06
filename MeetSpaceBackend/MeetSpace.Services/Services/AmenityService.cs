using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseServices;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Services
{
    public class AmenityService : BaseCRUDService<AmenityResponse, AmenitySearchObject, Amenity, AmenityInsertRequest, AmenityUpdateRequest>,
        IAmenityService
    {
        public AmenityService(MeetSpaceDbContext context, IMapper mapper)
           : base(context, mapper)
        {
        }

        // ApplyFilter za pretragu po poljima AmenitySearchObject
        protected override IQueryable<Amenity> ApplyFilter(IQueryable<Amenity> query, AmenitySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(a => a.Name.Contains(search.Name));
            }

            if (search.AmenityCategoryId.HasValue)
            {
                query = query.Where(a => a.AmenityCategoryId == search.AmenityCategoryId.Value);
            }

            return query;
        }

        protected override async Task BeforeUpdate(Amenity entity, AmenityUpdateRequest request, CancellationToken cancellationToken = default)
        {
            entity.UpdatedAt = DateTime.UtcNow;
            await base.BeforeUpdate(entity, request, cancellationToken);
        }
    }
}
