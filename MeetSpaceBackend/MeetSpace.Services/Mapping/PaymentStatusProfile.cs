using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class PaymentStatusProfile : Profile
    {
        public PaymentStatusProfile()
        {
            CreateMap<PaymentStatus, PaymentStatusResponse>();

            CreateMap<PaymentStatusInsertRequest, PaymentStatus>();

            CreateMap<PaymentStatusUpdateRequest, PaymentStatus>()
                .ForMember(dest => dest.Id, opt => opt.Ignore());
        }
    }
}
