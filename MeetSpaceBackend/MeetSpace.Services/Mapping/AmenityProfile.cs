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
    public class AmenityProfile : Profile
    {
        public AmenityProfile()
        {
            // Entity -> Response
            CreateMap<Amenity, AmenityResponse>();

            // InsertRequest -> Entity
            CreateMap<AmenityInsertRequest, Amenity>();

            // UpdateRequest -> Entity
            CreateMap<AmenityUpdateRequest, Amenity>()
                // Ignoriramo Id i CreatedAt da se ne prepišu
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());
        }
    }
}
