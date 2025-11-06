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
    public class SpaceTypeProfile : Profile
    {
        public SpaceTypeProfile() 
        {
            // Entity -> Response
            CreateMap<SpaceType, SpaceTypeResponse>();

            // InsertRequest -> Entity
            CreateMap<SpaceTypeInsertRequest, SpaceType>();

            // UpdateRequest -> Entity
            CreateMap<SpaceTypeUpdateRequest, SpaceType>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
