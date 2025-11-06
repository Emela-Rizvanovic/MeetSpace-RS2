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
    public class AmenityCategoryProfile : Profile
    {
        public AmenityCategoryProfile()
        {
            // Entity -> Response
            CreateMap<AmenityCategory, AmenityCategoryResponse>();

            // InsertRequest -> Entity
            CreateMap<AmenityCategoryInsertRequest, AmenityCategory>();

            // UpdateRequest -> Entity
            CreateMap<AmenityCategoryUpdateRequest, AmenityCategory>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
