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
    public class SpaceProfile : Profile
    {
        public SpaceProfile()
        {
            // Entity -> Response
            CreateMap<Space, SpaceResponse>()
    .ForMember(d => d.FacilityName,
        opt => opt.MapFrom(s => s.Facility != null ? s.Facility.Name : null))
    .ForMember(d => d.FacilityAddress,
        opt => opt.MapFrom(s => s.Facility != null ? s.Facility.Address : null))
    // ✅ NEW
    .ForMember(d => d.Amenities,
        opt => opt.MapFrom(s =>
            s.SpaceAmenities
             .Where(sa => sa.Amenity != null)
             .Select(sa => sa.Amenity!)));



            // InsertRequest -> Entity
            CreateMap<SpaceInsertRequest, Space>()
                 .ForMember(dest => dest.Images, opt => opt.Ignore());

            // UpdateRequest -> Entity
            CreateMap<SpaceUpdateRequest, Space>()
                // Ignoriramo Id i CreatedAt da se ne prepišu
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.Images, opt => opt.Ignore());

            CreateMap<SpaceImage, SpaceImageResponse>();
        }
    }
}
