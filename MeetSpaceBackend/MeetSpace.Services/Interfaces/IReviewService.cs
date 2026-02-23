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
    public interface IReviewService : ICRUDService<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        Task<double> GetAverageRatingAsync(int spaceId);
        Task<int> GetReviewCountAsync(int spaceId);
    }
}
