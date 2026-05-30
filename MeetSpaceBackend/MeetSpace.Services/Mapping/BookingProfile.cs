using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class BookingProfile : Profile
    {
        public BookingProfile()
        {
            CreateMap<Booking, BookingResponse>()
                .ForMember(d => d.SpaceName, opt => opt.MapFrom(s => s.Space != null ? s.Space.Name : null))
                .ForMember(d => d.StatusName, opt => opt.MapFrom(s => s.BookingStatus != null ? s.BookingStatus.Name : null))
                .ForMember(d => d.FacilityAddress, opt => opt.MapFrom(s =>
                    s.Space != null && s.Space.Facility != null ? s.Space.Facility.Address : null
                )).ForMember(d => d.Username, opt => opt.MapFrom(s =>
    s.User != null ? s.User.Username : null
))
                .ForMember(d => d.SpaceImageUrl, opt => opt.MapFrom(s =>
    s.Space != null && s.Space.Images != null && s.Space.Images.Any()
        ? s.Space.Images.First().ImageUrl
        : null
))
                .ForMember(dest => dest.UserFullName,
    opt => opt.MapFrom(src => src.User.FirstName + " " + src.User.LastName))

.ForMember(dest => dest.UserEmail,
    opt => opt.MapFrom(src => src.User.Email))

.ForMember(dest => dest.UserPhone,
    opt => opt.MapFrom(src => src.User.PhoneNumber))
.ForMember(dest => dest.RejectionReason,
    opt => opt.MapFrom(src => src.RejectionReason))
.ForMember(dest => dest.PaymentStatusName,
    opt => opt.MapFrom(src => src.PaymentStatus.Name));

            CreateMap<BookingInsertRequest, Booking>()
                .ForMember(d => d.Id, opt => opt.Ignore())
                .ForMember(d => d.CreatedAt, opt => opt.Ignore())
                .ForMember(d => d.UpdatedAt, opt => opt.Ignore())
                .ForMember(d => d.Space, opt => opt.Ignore())
                .ForMember(d => d.User, opt => opt.Ignore())
                .ForMember(d => d.BookingStatus, opt => opt.Ignore())
                .ForMember(d => d.BookingAmenities, opt => opt.Ignore())
                .ForMember(d => d.Payments, opt => opt.Ignore());

            CreateMap<BookingUpdateRequest, Booking>()
                .ForMember(d => d.Id, opt => opt.Ignore())
                .ForMember(d => d.CreatedAt, opt => opt.Ignore())
                .ForMember(d => d.Space, opt => opt.Ignore())
                .ForMember(d => d.User, opt => opt.Ignore())
                .ForMember(d => d.BookingStatus, opt => opt.Ignore())
                .ForMember(d => d.BookingAmenities, opt => opt.Ignore())
                .ForMember(d => d.Payments, opt => opt.Ignore());
        }
    }
}
