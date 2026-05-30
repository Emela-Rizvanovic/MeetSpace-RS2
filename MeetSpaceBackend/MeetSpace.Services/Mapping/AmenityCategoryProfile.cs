using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class AmenityCategoryProfile : Profile
    {
        public AmenityCategoryProfile()
        {
            CreateMap<AmenityCategory, AmenityCategoryResponse>();

            CreateMap<AmenityCategoryInsertRequest, AmenityCategory>();

            CreateMap<AmenityCategoryUpdateRequest, AmenityCategory>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
