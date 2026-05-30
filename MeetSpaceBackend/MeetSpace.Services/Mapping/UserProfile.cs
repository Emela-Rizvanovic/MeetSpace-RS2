using AutoMapper;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Mapping
{
    public class UserProfile : Profile
    {
        public UserProfile() 
        {
            CreateMap<User, UserResponse>()
                .ForMember(dest => dest.RoleName, opt => opt.MapFrom(src => src.Role != null ? src.Role.Name : null));

            CreateMap<UserInsertRequest, User>();

            CreateMap<UserUpdateRequest, User>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.PasswordHash, opt => opt.Ignore()); 
        }
    }
}
