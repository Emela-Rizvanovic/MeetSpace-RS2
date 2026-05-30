using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<SpaceResponse>> GetRecommendedSpaces(int userId, int count = 5);
        Task MarkClickedAsync(
    int userId,
    int spaceId,
    CancellationToken ct = default);
    }
}
