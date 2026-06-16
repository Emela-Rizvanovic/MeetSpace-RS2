using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class NotificationTypeProfile : Profile
    {
        public NotificationTypeProfile()
        {
            CreateMap<NotificationType, NotificationTypeResponse>();

            CreateMap<NotificationTypeInsertRequest, NotificationType>();

            CreateMap<NotificationTypeUpdateRequest, NotificationType>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.Notifications, opt => opt.Ignore());
        }
    }
}