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
    public class PaymentMethodProfile : Profile
    {
        public PaymentMethodProfile()
        {
            // Entity -> Response
            CreateMap<PaymentMethod, PaymentMethodResponse>();

            // InsertRequest -> Entity
            CreateMap<PaymentMethodInsertRequest, PaymentMethod>();

            // UpdateRequest -> Entity
            CreateMap<PaymentMethodUpdateRequest, PaymentMethod>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
