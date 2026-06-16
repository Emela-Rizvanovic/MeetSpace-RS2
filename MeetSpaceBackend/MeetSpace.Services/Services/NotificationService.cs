using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Exceptions;
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
            var type = message.NotificationType;

            if (type == null)
            {
                if (message.IsCancellation)
                    type = NotificationTypeEnum.BookingCancelled;
                else if (message.IsApproved)
                    type = NotificationTypeEnum.BookingApproved;
                else
                    type = NotificationTypeEnum.BookingRejected;
            }

            var title = type switch
            {
                NotificationTypeEnum.BookingApproved => "Booking approved",
                NotificationTypeEnum.BookingRejected => "Booking rejected",
                NotificationTypeEnum.BookingCancelled => "Booking cancelled",
                NotificationTypeEnum.PaymentAuthorized => "Payment authorized",
                NotificationTypeEnum.PaymentCompleted => "Payment completed",
                NotificationTypeEnum.UserBookingCancelled => "Booking cancelled by user",
                NotificationTypeEnum.BookingCreated => "New booking request",
                _ => "Notification"
            };

            var manualReviewText = message.RequiresManualPaymentReview
    ? "\nPayment was already completed for this approved reservation. Manual refund review is required because automatic refund is not implemented."
    : "";

            var text = type switch
            {
                NotificationTypeEnum.BookingApproved =>
                    $"Your reservation for {message.SpaceName} has been approved.",

                NotificationTypeEnum.BookingRejected =>
                    $"Your reservation for {message.SpaceName} was rejected. \nReason: {message.Reason}",

                NotificationTypeEnum.BookingCancelled =>
    $"Your reservation for {message.SpaceName} was cancelled. \nReason: {message.Reason}{manualReviewText}",

                NotificationTypeEnum.PaymentAuthorized =>
                    $"Your payment for {message.SpaceName} was authorized. Your reservation is waiting for administrator approval.",

                NotificationTypeEnum.PaymentCompleted =>
                    $"Your payment for {message.SpaceName} has been completed.",

                NotificationTypeEnum.UserBookingCancelled =>
    $"{message.ActorUsername ?? "User"} cancelled a reservation for {message.SpaceName}. \nReason: {message.Reason}{manualReviewText}",

                NotificationTypeEnum.BookingCreated =>
                $"{message.ActorUsername ?? "User"} created a pending reservation for {message.SpaceName}. Please review it.",

                _ => $"Notification for {message.SpaceName}."
            };

            var notification = new Notification
            {
                UserId = message.UserId,
                NotificationTypeId = (int)type.Value,
                Title = title,
                Message = text,
                IsRead = false,
                RelatedBookingId = message.RelatedBookingId,
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
                RelatedBookingId = message.RelatedBookingId,
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

        public async Task MarkAsReadAsync(
    int notificationId,
    int userId,
    CancellationToken ct = default)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(x => x.Id == notificationId && x.UserId == userId, ct);

            if (notification == null)
                throw new NotFoundException("Notification not found.");

            notification.IsRead = true;
            notification.UpdatedAt = DateTime.UtcNow;

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