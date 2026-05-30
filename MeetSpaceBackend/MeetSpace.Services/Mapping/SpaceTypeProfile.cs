using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class SpaceTypeProfile : Profile
    {
        public SpaceTypeProfile() 
        {
            CreateMap<SpaceType, SpaceTypeResponse>();

            CreateMap<SpaceTypeInsertRequest, SpaceType>();

            CreateMap<SpaceTypeUpdateRequest, SpaceType>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
