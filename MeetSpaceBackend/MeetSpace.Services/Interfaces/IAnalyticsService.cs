using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Interfaces
{
    public interface IAnalyticsService
    {
        Task<IReadOnlyList<SpaceDemandResponse>> GetSpaceDemandAsync(
            string? cityCode,
            string? facilityCode,
            string? spaceTypeCode,
            string? spaceCode,
            DateTime? fromDate,
            DateTime? toDate,
            CancellationToken cancellationToken = default);

        Task<IReadOnlyList<SpaceDemandPeriodResponse>> GetSpaceDemandPeriodsAsync(
            string spaceCode,
            DateTime? fromDate = null,
            DateTime? toDate = null,
            CancellationToken cancellationToken = default);
    }
}
