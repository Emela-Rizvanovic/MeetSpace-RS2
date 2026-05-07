using MeetSpace.API.Hubs;
using MeetSpace.Models.Messages;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly IHubContext<NotificationHub> _hubContext;

    public NotificationsController(IHubContext<NotificationHub> hubContext)
    {
        _hubContext = hubContext;
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendNotification([FromBody] BookingStatusChangedMessage message)
    {

       /* await _hubContext.Clients.All
    .SendAsync("ReceiveNotification", new { title = "TEST" });*/

       await _hubContext.Clients.User(message.UserId.ToString())
            .SendAsync("ReceiveNotification", new
            {
                title = message.IsApproved ? "Booking approved" : "Booking rejected",
                space = message.SpaceName,
                date = message.StartTime,
                reason = message.Reason
            });

        return Ok();
    }

    [HttpPost("reminder")]
    public async Task<IActionResult> SendReminder(
    [FromBody] BookingReminderMessage message)
    {
        await _hubContext.Clients.User(message.UserId.ToString())
            .SendAsync("ReceiveNotification", new
            {
                title = "Upcoming booking!",
                space = message.SpaceName,
                date = message.StartTime,
                type = "reminder"
            });

        return Ok();
    }
}