using MeetSpace.Models.Messages;

namespace MeetSpace.Subscriber.Services
{
    public interface IEmailService
    {
        Task SendPasswordResetEmailAsync(PasswordResetRequested message);
    }
}
