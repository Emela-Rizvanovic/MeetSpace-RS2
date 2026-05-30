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
    public class RoleService
    : BaseCRUDService<RoleResponse, RoleSearchObject, Role, RoleInsertRequest, RoleUpdateRequest>,
        IRoleService
    {
        public RoleService(MeetSpaceDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }
        protected override IQueryable<Role> ApplyFilter(IQueryable<Role> query, RoleSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return query;
        }
    }
}