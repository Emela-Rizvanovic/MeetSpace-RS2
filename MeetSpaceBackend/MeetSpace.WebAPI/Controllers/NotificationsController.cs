using MeetSpace.API.Hubs;
using MeetSpace.Models.Messages;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly INotificationService _notificationService;

    public NotificationsController(
      IHubContext<NotificationHub> hubContext,
      INotificationService notificationService)
    {
        _hubContext = hubContext;
        _notificationService = notificationService;
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendNotification(
    [FromBody] BookingStatusChangedMessage message,
    CancellationToken ct)
    {
        var notification =
            await _notificationService.CreateBookingStatusNotificationAsync(message, ct);

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
            }, ct);

        return Ok();
    }

    [HttpPost("reminder")]
    public async Task<IActionResult> SendReminder(
        [FromBody] BookingReminderMessage message,
        CancellationToken ct)
    {
        var notification =
            await _notificationService.CreateReminderNotificationAsync(message, ct);

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
            }, ct);

        return Ok();
    }

    [HttpGet]
    public async Task<ActionResult<List<NotificationResponse>>> GetNotifications(
        [FromQuery] int userId,
        CancellationToken ct)
    {
        var notifications =
            await _notificationService.GetByUserAsync(userId, ct);

        return Ok(notifications);
    }

    [HttpPut("mark-all-read")]
    public async Task<IActionResult> MarkAllRead(
      [FromQuery] int userId,
      CancellationToken ct)
    {
        await _notificationService.MarkAllAsReadAsync(userId, ct);

        return Ok();
    }
}