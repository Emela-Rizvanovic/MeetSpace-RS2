using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseInterfaces;

namespace MeetSpace.Services.Interfaces
{
    public interface IRevenueService
        : IService<RevenueResponse, RevenueSearchObject>
    {
        Task<List<RevenueResponse>> GetLatest();
        Task<double> GetTotal();
    }
}