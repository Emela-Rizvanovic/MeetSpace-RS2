using MeetSpace.Models.Entities;
using MeetSpace.Models.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<SpaceResponse>> GetRecommendedSpaces(int userId, int count = 5);
    }
}
