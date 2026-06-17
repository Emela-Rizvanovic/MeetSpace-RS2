using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseInterfaces;

namespace MeetSpace.Services.Interfaces
{
    public interface IBookingService : ICRUDService<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
    {
        Task<List<BookingResponse>> GetByUserIdAsync(int userId, CancellationToken ct = default);
        Task<List<BookingResponse>> GetBySpaceIdAsync(int spaceId, CancellationToken ct = default);
        Task<List<BookingAvailabilityResponse>> GetAvailabilityBySpaceIdAsync(int spaceId, CancellationToken ct = default);
        Task ApproveAsync(int id, CancellationToken ct = default);
        Task RejectAsync(int id, string reason, CancellationToken ct = default);
        Task CancelAsync(int id, string reason, CancellationToken ct = default);
        Task<bool> HasConflict(int spaceId, DateTime start, DateTime end, int? ignoreId = null);
        Task<decimal> ValidateCreatePrerequisitesAndCalculatePriceAsync(
    int spaceId,
    DateTime startTime,
    DateTime endTime,
    List<BookingAmenityInsertRequest>? amenities,
    CancellationToken ct = default);
        Task SendReminderAsync(int bookingId, CancellationToken ct = default);
        Task<TicketValidationResponse> ValidateTicketAsync(string qrData, CancellationToken ct = default);
    }
}
