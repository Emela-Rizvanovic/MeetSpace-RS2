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
    public class SpaceTypeService
      : BaseCRUDService<SpaceTypeResponse, SpaceTypeSearchObject, SpaceType, SpaceTypeInsertRequest, SpaceTypeUpdateRequest>,
        ISpaceTypeService
    {
        public SpaceTypeService(MeetSpaceDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        // Filter za pretragu po nazivu
        protected override IQueryable<SpaceType> ApplyFilter(IQueryable<SpaceType> query, SpaceTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return query;
        }

        // protected override async Task BeforeUpdate(...) { } ?
    }
}
