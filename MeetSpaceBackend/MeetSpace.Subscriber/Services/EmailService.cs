using MeetSpace.Models.Messages;
using System.Net;
using System.Net.Mail;

namespace MeetSpace.Subscriber.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;
        private readonly string _smtpHost;
        private readonly int _smtpPort;
        private readonly string _smtpUsername;
        private readonly string _smtpPassword;
        private readonly string _smtpFrom;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
            _smtpHost = Environment.GetEnvironmentVariable("SMTP_HOST")!;
            _smtpPort = int.Parse(Environment.GetEnvironmentVariable("SMTP_PORT")!);
            _smtpUsername = Environment.GetEnvironmentVariable("SMTP_USERNAME")!;
            _smtpPassword = Environment.GetEnvironmentVariable("SMTP_PASSWORD")!;
            _smtpFrom = Environment.GetEnvironmentVariable("SMTP_FROM")!;
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

            using var smtp = new SmtpClient(_smtpHost)
            {
                Port = _smtpPort,
                EnableSsl = true,
                Credentials = new NetworkCredential(
        _smtpUsername,
        _smtpPassword)
            };

            await smtp.SendMailAsync(
               new MailMessage(
    _smtpFrom,
    message.UserEmail)
               {
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                });
        }
    }

}
