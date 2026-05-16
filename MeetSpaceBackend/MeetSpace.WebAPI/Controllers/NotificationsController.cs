using MeetSpace.API.Hubs;
using MeetSpace.Models.Entities;
using MeetSpace.Models.Enums;
using MeetSpace.Models.Messages;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Database;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly MeetSpaceDbContext _context;

    public NotificationsController(
        IHubContext<NotificationHub> hubContext,
        MeetSpaceDbContext context)
    {
        _hubContext = hubContext;
        _context = context;
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendNotification(
        [FromBody] BookingStatusChangedMessage message)
    {
        var isApproved = message.IsApproved;

        var notification = new Notification
        {
            UserId = message.UserId,
            NotificationTypeId = isApproved ? 1 : 2,
            Title = isApproved
                ? "Booking approved"
                : "Booking rejected",

            Message = isApproved
                ? $"Your reservation for {message.SpaceName} has been approved."
                : $"Your reservation for {message.SpaceName} was rejected. \nReason: {message.Reason}",

            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        await _context.Notifications.AddAsync(notification);

        await _context.SaveChangesAsync();

        await _hubContext.Clients
            .User(message.UserId.ToString())
            .SendAsync("ReceiveNotification", new
            {
                id = notification.Id,
                title = notification.Title,
                message = notification.Message,
                date = message.StartTime,
                reason = message.Reason,
                isRead = notification.IsRead
            });

        return Ok();
    }

    [HttpPost("reminder")]
    public async Task<IActionResult> SendReminder(
        [FromBody] BookingReminderMessage message)
    {
        var notification = new Notification
        {
            UserId = message.UserId,
            NotificationTypeId = (int)NotificationTypeEnum.BookingReminder,
            Title = "Upcoming booking!",
            Message =
                $"Don't forget your reservation at {message.SpaceName}.",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        await _context.Notifications.AddAsync(notification);

        await _context.SaveChangesAsync();

        await _hubContext.Clients
            .User(message.UserId.ToString())
            .SendAsync("ReceiveNotification", new
            {
                id = notification.Id,
                title = notification.Title,
                message = notification.Message,
                date = message.StartTime,
                type = "reminder",
                isRead = notification.IsRead
            });

        return Ok();
    }

    [HttpGet]
    public async Task<ActionResult<List<NotificationResponse>>> GetNotifications(
        [FromQuery] int userId)
    {
        var notifications = await _context.Notifications
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
            .ToListAsync();

        return Ok(notifications);
    }

    [HttpPut("mark-all-read")]
    public async Task<IActionResult> MarkAllRead(
        [FromQuery] int userId)
    {
        var notifications = await _context.Notifications
            .Where(x => x.UserId == userId && !x.IsRead)
            .ToListAsync();

        foreach (var item in notifications)
        {
            item.IsRead = true;
        }

        await _context.SaveChangesAsync();

        return Ok();
    }
}