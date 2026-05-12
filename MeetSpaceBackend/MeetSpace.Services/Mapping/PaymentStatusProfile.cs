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
    public class PaymentStatusProfile : Profile
    {
        public PaymentStatusProfile()
        {
            // Entity -> Response
            CreateMap<PaymentStatus, PaymentStatusResponse>();

            // InsertRequest -> Entity
            CreateMap<PaymentStatusInsertRequest, PaymentStatus>();

            // UpdateRequest -> Entity
            CreateMap<PaymentStatusUpdateRequest, PaymentStatus>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
