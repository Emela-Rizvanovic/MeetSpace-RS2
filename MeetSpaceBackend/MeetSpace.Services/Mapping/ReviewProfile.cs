using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class ReviewProfile : Profile
    {
        public ReviewProfile()
        {
            // Entity -> Response
            CreateMap<Review, ReviewResponse>();

            // InsertRequest -> Entity
            CreateMap<ReviewInsertRequest, Review>()
                .ForMember(d => d.Id, opt => opt.Ignore())
                .ForMember(d => d.CreatedAt, opt => opt.Ignore())
                .ForMember(d => d.UpdatedAt, opt => opt.Ignore())
                .ForMember(d => d.User, opt => opt.Ignore())
                .ForMember(d => d.Space, opt => opt.Ignore());

            // UpdateRequest -> Entity
            CreateMap<ReviewUpdateRequest, Review>()
                .ForMember(d => d.Id, opt => opt.Ignore())
                .ForMember(d => d.CreatedAt, opt => opt.Ignore())
                .ForMember(d => d.User, opt => opt.Ignore())
                .ForMember(d => d.Space, opt => opt.Ignore());

            CreateMap<Review, ReviewResponse>()
    .ForMember(d => d.UserName,
        opt => opt.MapFrom(s => s.User != null ? s.User.FirstName + " " + s.User.LastName : null))
    .ForMember(dest => dest.SpaceName,
        opt => opt.MapFrom(src => src.Space.Name));
        }
    }
}