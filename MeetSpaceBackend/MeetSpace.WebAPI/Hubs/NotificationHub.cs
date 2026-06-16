using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace MeetSpace.API.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
    }
}