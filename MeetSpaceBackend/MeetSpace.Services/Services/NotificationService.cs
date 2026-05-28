using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Messages;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MeetSpace.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly MeetSpaceDbContext _context;

        public NotificationService(MeetSpaceDbContext context)
        {
            _context = context;
        }

        public async Task<NotificationResponse> CreateBookingStatusNotificationAsync(
            BookingStatusChangedMessage message,
            CancellationToken ct = default)
        {
            var isApproved = message.IsApproved;

            var notification = new Notification
            {
                UserId = message.UserId,
                NotificationTypeId = isApproved
                    ? (int)NotificationTypeEnum.BookingApproved
                    : (int)NotificationTypeEnum.BookingRejected,
                Title = message.IsCancellation
    ? "Booking cancelled"
    : isApproved
        ? "Booking approved"
        : "Booking rejected",

                Message = message.IsCancellation
    ? $"Your reservation for {message.SpaceName} was cancelled. \nReason: {message.Reason}"
    : isApproved
        ? $"Your reservation for {message.SpaceName} has been approved."
        : $"Your reservation for {message.SpaceName} was rejected. \nReason: {message.Reason}",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            await _context.Notifications.AddAsync(notification, ct);
            await _context.SaveChangesAsync(ct);

            return MapToResponse(notification);
        }

        public async Task<NotificationResponse> CreateReminderNotificationAsync(
            BookingReminderMessage message,
            CancellationToken ct = default)
        {
            var notification = new Notification
            {
                UserId = message.UserId,
                NotificationTypeId = (int)NotificationTypeEnum.BookingReminder,
                Title = "Upcoming booking!",
                Message = $"Don't forget your reservation at {message.SpaceName}.",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            await _context.Notifications.AddAsync(notification, ct);
            await _context.SaveChangesAsync(ct);

            return MapToResponse(notification);
        }

        public async Task<List<NotificationResponse>> GetByUserAsync(
            int userId,
            CancellationToken ct = default)
        {
            return await _context.Notifications
                .Include(x => x.NotificationType)
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt)
                .Select(x => new NotificationResponse
                {
                    Id = x.Id,
                    Title = x.Title,
                    Message = x.Message,
                    IsRead = x.IsRead,
                    CreatedAt = x.CreatedAt,
                    RelatedBookingId = x.RelatedBookingId,
                    NotificationType = x.NotificationType.Name
                })
                .ToListAsync(ct);
        }

        public async Task MarkAllAsReadAsync(
            int userId,
            CancellationToken ct = default)
        {
            var notifications = await _context.Notifications
                .Where(x => x.UserId == userId && !x.IsRead)
                .ToListAsync(ct);

            foreach (var item in notifications)
            {
                item.IsRead = true;
            }

            await _context.SaveChangesAsync(ct);
        }

        private static NotificationResponse MapToResponse(Notification notification)
        {
            return new NotificationResponse
            {
                Id = notification.Id,
                Title = notification.Title,
                Message = notification.Message,
                IsRead = notification.IsRead,
                CreatedAt = notification.CreatedAt,
                RelatedBookingId = notification.RelatedBookingId,
                NotificationType = notification.NotificationType?.Name
            };
        }
    }
}