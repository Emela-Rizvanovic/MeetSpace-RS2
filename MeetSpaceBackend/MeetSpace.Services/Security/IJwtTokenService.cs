using MeetSpace.Models.Entities;

namespace MeetSpace.Services.Security
{
    public interface IJwtTokenService
    {
        string GenerateToken(User user);
    }
}
