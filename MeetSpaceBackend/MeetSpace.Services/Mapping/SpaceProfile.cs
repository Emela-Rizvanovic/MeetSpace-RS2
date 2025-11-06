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
            CreateMap<Space, SpaceResponse>();

            // InsertRequest -> Entity
            CreateMap<SpaceInsertRequest, Space>();

            // UpdateRequest -> Entity
            CreateMap<SpaceUpdateRequest, Space>()
                // Ignoriramo Id i CreatedAt da se ne prepišu
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());
        }
    }
}
