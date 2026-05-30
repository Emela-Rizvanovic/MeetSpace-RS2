using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class FacilityProfile : Profile
    {
        public FacilityProfile() 
        {
            CreateMap<Facility, FacilityResponse>()
    .ForMember(
        dest => dest.CityName,
        opt => opt.MapFrom(src => src.City.Name))
    .ForMember(
        dest => dest.CountryName,
        opt => opt.MapFrom(src => src.City.Country.Name));

            CreateMap<FacilityInsertRequest, Facility>();

            CreateMap<FacilityUpdateRequest, Facility>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());
        }
    }
}
