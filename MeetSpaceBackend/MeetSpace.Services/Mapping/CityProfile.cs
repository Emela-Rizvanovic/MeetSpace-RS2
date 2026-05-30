using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class CityProfile : Profile
    {
        public CityProfile() {
            CreateMap<City, CityResponse>()
    .ForMember(
        dest => dest.CountryName,
        opt => opt.MapFrom(src => src.Country.Name));

            CreateMap<CityInsertRequest, City>();

            CreateMap<CityUpdateRequest, City>()
                .ForAllMembers(opts =>
                    opts.Condition((src, dest, srcMember) =>
                        srcMember != null));

        }
    }
}
