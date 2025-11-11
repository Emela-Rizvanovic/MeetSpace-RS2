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
    public class UserProfile : Profile
    {
        public UserProfile() 
        {
            // Entity -> Response
            CreateMap<User, UserResponse>()
                .ForMember(dest => dest.RoleName, opt => opt.MapFrom(src => src.Role != null ? src.Role.Name : null));

            // InsertRequest -> Entity
            CreateMap<UserInsertRequest, User>();

            // UpdateRequest -> Entity
            CreateMap<UserUpdateRequest, User>()
                // Ignoriramo polja koja se ne smiju ručno mijenjati
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.PasswordHash, opt => opt.Ignore()); // hash kasnije rješavamo posebno
        }
    }
}
