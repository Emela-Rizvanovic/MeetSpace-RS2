using MeetSpace.Models.Messages;
using MeetSpace.Models.Responses;

namespace MeetSpace.Services.Interfaces
{
    public interface INotificationService
    {
        Task<NotificationResponse> CreateBookingStatusNotificationAsync(
            BookingStatusChangedMessage message,
            CancellationToken ct = default);

        Task<NotificationResponse> CreateReminderNotificationAsync(
            BookingReminderMessage message,
            CancellationToken ct = default);

        Task<List<NotificationResponse>> GetByUserAsync(
            int userId,
            CancellationToken ct = default);

        Task MarkAllAsReadAsync(
            int userId,
            CancellationToken ct = default);

        Task MarkAsReadAsync(int notificationId, int userId, CancellationToken ct = default);
    }
}