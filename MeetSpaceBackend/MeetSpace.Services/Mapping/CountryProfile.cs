using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class CountryProfile : Profile
    {
        public CountryProfile()
        {
            CreateMap<Country, CountryResponse>();

            CreateMap<CountryInsertRequest, Country>();

            CreateMap<CountryUpdateRequest, Country>()
                .ForAllMembers(opts =>
                    opts.Condition((src, dest, srcMember) =>
                        srcMember != null));
        }
    }
}
