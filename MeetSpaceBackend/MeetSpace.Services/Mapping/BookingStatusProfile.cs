using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class BookingStatusProfile : Profile
    {
        public BookingStatusProfile()
        {
            CreateMap<BookingStatus, BookingStatusResponse>();

            CreateMap<BookingStatusInsertRequest, BookingStatus>();

            CreateMap<BookingStatusUpdateRequest, BookingStatus>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.Bookings, opt => opt.Ignore());
        }
    }
}
