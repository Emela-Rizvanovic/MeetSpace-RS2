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
    public class FacilityProfile : Profile
    {
        public FacilityProfile() 
        {
            // Entity -> Response
            CreateMap<Facility, FacilityResponse>()
    .ForMember(
        dest => dest.CityName,
        opt => opt.MapFrom(src => src.City.Name))
    .ForMember(
        dest => dest.CountryName,
        opt => opt.MapFrom(src => src.City.Country.Name));

            // InsertRequest -> Entity
            CreateMap<FacilityInsertRequest, Facility>();

            // UpdateRequest -> Entity
            CreateMap<FacilityUpdateRequest, Facility>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());
        }
    }
}
