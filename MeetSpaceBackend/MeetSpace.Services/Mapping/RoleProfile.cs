using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
namespace MeetSpace.Services.Mapping
{
    public class RoleProfile : Profile
    {
        public RoleProfile() 
        {
            CreateMap<Role, RoleResponse>();

            CreateMap<RoleInsertRequest, Role>();

            CreateMap<RoleUpdateRequest, Role>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
