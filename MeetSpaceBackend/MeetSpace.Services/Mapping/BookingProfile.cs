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
    public class BookingProfile : Profile
    {
        public BookingProfile()
        {
            // Entity -> Response
            CreateMap<Booking, BookingResponse>()
                .ForMember(d => d.SpaceName, opt => opt.MapFrom(s => s.Space != null ? s.Space.Name : null))
                .ForMember(d => d.StatusName, opt => opt.MapFrom(s => s.BookingStatus != null ? s.BookingStatus.Name : null))
                .ForMember(d => d.FacilityAddress, opt => opt.MapFrom(s =>
                    s.Space != null && s.Space.Facility != null ? s.Space.Facility.Address : null
                ));

            // InsertRequest -> Entity
            CreateMap<BookingInsertRequest, Booking>()
                .ForMember(d => d.Id, opt => opt.Ignore())
                .ForMember(d => d.CreatedAt, opt => opt.Ignore())
                .ForMember(d => d.UpdatedAt, opt => opt.Ignore())
                .ForMember(d => d.Space, opt => opt.Ignore())
                .ForMember(d => d.User, opt => opt.Ignore())
                .ForMember(d => d.BookingStatus, opt => opt.Ignore())
                .ForMember(d => d.BookingAmenities, opt => opt.Ignore())
                .ForMember(d => d.Payments, opt => opt.Ignore());

            // UpdateRequest -> Entity
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
