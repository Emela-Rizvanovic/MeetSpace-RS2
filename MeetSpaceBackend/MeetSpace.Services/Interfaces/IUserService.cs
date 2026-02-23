using MeetSpace.Models.Entities;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseInterfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Interfaces
{
    public interface IUserService : ICRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Task<UserResponse?> AuthenticateUser(UserLoginRequest request, CancellationToken ct = default);
        Task<UserResponse> AuthenticateAdmin(UserLoginRequest request, CancellationToken ct);
        Task<UserResponse> RegisterAsync(UserInsertRequest request, CancellationToken ct);
<<<<<<< Updated upstream
=======
        Task<ForgotPasswordResponse> RequestPasswordResetAsync(ForgotPasswordRequest request, CancellationToken ct = default);
        Task<ForgotPasswordResponse> ResetPasswordAsync(ResetPasswordRequest request, CancellationToken ct = default);
        Task<User?> GetEntityByUsername(string username, CancellationToken ct);
>>>>>>> Stashed changes
    }
}
