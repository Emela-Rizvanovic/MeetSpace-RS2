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
    public class SpaceService : BaseCRUDService<SpaceResponse, SpaceSearchObject, Space, SpaceInsertRequest, SpaceUpdateRequest>, ISpaceService
    {
        public SpaceService(MeetSpaceDbContext context, IMapper mapper)
            : base(context, mapper)
        {
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

        // TO-DO 
        // dodati ako bude trebalo u buducnosti Task BeforeUpdate, BeforeInsert, DeleteAsync
    }
}
