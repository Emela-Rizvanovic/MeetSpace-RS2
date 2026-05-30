using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class AmenityProfile : Profile
    {
        public AmenityProfile()
        {
            CreateMap<Amenity, AmenityResponse>();

            CreateMap<AmenityInsertRequest, Amenity>();

            CreateMap<AmenityUpdateRequest, Amenity>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());
        }
    }
}
