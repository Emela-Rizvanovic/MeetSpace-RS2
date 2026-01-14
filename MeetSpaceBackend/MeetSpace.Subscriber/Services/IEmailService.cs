using MeetSpace.Models.Messages;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Subscriber.Services
{
    public interface IEmailService
    {
        Task SendPasswordResetEmailAsync(PasswordResetRequested message);
    }
}
