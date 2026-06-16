using MeetSpace.API.Hubs;
using MeetSpace.Models.Messages;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using MeetSpace.Models.Constants;

[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly INotificationService _notificationService;
    private readonly string _internalApiKey;

    public NotificationsController(
    IHubContext<NotificationHub> hubContext,
    INotificationService notificationService)
    {
        _hubContext = hubContext;
        _notificationService = notificationService;
        _internalApiKey = Environment.GetEnvironmentVariable("INTERNAL_API_SECRET")
            ?? throw new InvalidOperationException("INTERNAL_API_SECRET is not configured.");
    }
    private bool IsInternalRequest()
    {
        if (!Request.Headers.TryGetValue(InternalAuthConstants.HeaderName, out var providedKey))
            return false;

        return providedKey == _internalApiKey;
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendNotification(
    [FromBody] BookingStatusChangedMessage message,
    CancellationToken ct)
    {
        if (!IsInternalRequest())
            return Forbid();

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
        if (!IsInternalRequest())
            return Forbid();

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

    [Authorize]
    [HttpGet]
    public async Task<ActionResult<List<NotificationResponse>>> GetNotifications(
     CancellationToken ct)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        int currentUserId = int.Parse(userIdClaim.Value);

        var notifications =
            await _notificationService.GetByUserAsync(currentUserId, ct);

        return Ok(notifications);
    }

    [Authorize]
    [HttpPut("mark-all-read")]
    public async Task<IActionResult> MarkAllRead(CancellationToken ct)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        int currentUserId = int.Parse(userIdClaim.Value);

        await _notificationService.MarkAllAsReadAsync(currentUserId, ct);

        return Ok();
    }

    [Authorize]
    [HttpPut("{id}/mark-read")]
    public async Task<IActionResult> MarkRead(int id, CancellationToken ct)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        int currentUserId = int.Parse(userIdClaim.Value);

        await _notificationService.MarkAsReadAsync(id, currentUserId, ct);

        return Ok();
    }
}