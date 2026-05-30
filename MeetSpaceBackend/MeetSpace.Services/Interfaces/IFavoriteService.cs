using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Interfaces
{
    public interface IFavoriteService
    {
        Task AddAsync(FavoriteInsertRequest request);
        Task RemoveAsync(int userId, int spaceId);
        Task<List<SpaceResponse>> GetByUserAsync(int userId);
    }
}
