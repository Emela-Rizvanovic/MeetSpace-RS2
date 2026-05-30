using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class PaymentMethodProfile : Profile
    {
        public PaymentMethodProfile()
        {
            CreateMap<PaymentMethod, PaymentMethodResponse>();

            CreateMap<PaymentMethodInsertRequest, PaymentMethod>();

            CreateMap<PaymentMethodUpdateRequest, PaymentMethod>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
