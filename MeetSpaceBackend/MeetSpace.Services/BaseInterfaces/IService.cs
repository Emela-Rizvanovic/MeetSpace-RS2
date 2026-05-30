using MeetSpace.Models.SearchObjects;

namespace MeetSpace.Services.BaseInterfaces
{
    public interface IService<T, TSearch> where T : class where TSearch : BaseSearchObject
    {
        Task<Models.Responses.PagedResult<T>> GetAsync(TSearch search, CancellationToken cancellationToken = default);
        Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    }
}
