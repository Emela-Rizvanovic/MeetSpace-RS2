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
    public class ReportTypeProfile : Profile
    {
        public ReportTypeProfile() 
        {
            // Entity -> Response
            CreateMap<ReportType, ReportTypeResponse>();

            // InsertRequest -> Entity
            CreateMap<ReportTypeInsertRequest, ReportType>();

            // UpdateRequest -> Entity
            CreateMap<ReportTypeUpdateRequest, ReportType>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
