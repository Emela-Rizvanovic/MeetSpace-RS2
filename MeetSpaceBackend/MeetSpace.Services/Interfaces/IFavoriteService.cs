using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Interfaces
{
    public interface IFavoriteService
    {
        Task AddAsync(FavoriteInsertRequest request);
        Task RemoveAsync(int userId, int spaceId);
        Task<List<SpaceResponse>> GetByUserAsync(int userId);
    }
}
