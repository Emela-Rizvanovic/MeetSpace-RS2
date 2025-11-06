using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Mapping
{
    public class RoleProfile : Profile
    {
        public RoleProfile() 
        {
            // Entity -> Response
            CreateMap<Role, RoleResponse>();

            // InsertRequest -> Entity
            CreateMap<RoleInsertRequest, Role>();

            // UpdateRequest -> Entity
            CreateMap<RoleUpdateRequest, Role>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
