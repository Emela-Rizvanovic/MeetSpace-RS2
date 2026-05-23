using MeetSpace.Models.Messages;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Subscriber.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendPasswordResetEmailAsync(PasswordResetRequested message)
        {
            var subject = "MeetSpace: Password Reset Code";
            var body = $@"
        <h2>Your reset code:</h2>
        <div style='font-size:32px;font-weight:bold;background:#eee;padding:10px;text-align:center'>
            {message.ResetCode}
        </div>
        <p>This code expires at {message.ExpiresAt.ToLocalTime():HH:mm}.</p>";

            using var smtp = new SmtpClient(
    Environment.GetEnvironmentVariable("SMTP_HOST"))
            {
                Port = int.Parse(
        Environment.GetEnvironmentVariable("SMTP_PORT")!),

                EnableSsl = true,

                Credentials = new NetworkCredential(
        Environment.GetEnvironmentVariable("SMTP_USERNAME"),
        Environment.GetEnvironmentVariable("SMTP_PASSWORD"))
            };

            await smtp.SendMailAsync(
                new MailMessage(
                    Environment.GetEnvironmentVariable("SMTP_FROM"),
                    message.UserEmail)
                {
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                });
        }
    }

}
