using MeetSpace.Models.Messages;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;

namespace MeetSpace.Subscriber.Services
{
    public class RabbitMQConsumerService : IRabbitMQConsumerService
    {
        private readonly IModel _channel;
        private readonly IEmailService _emailService;
        private readonly ILogger<RabbitMQConsumerService> _logger;

        public RabbitMQConsumerService(
            IConfiguration config,
            IEmailService emailService,
            ILogger<RabbitMQConsumerService> logger)
        {
            _emailService = emailService;
            _logger = logger;

            var factory = new ConnectionFactory()
            {
                HostName = Environment.GetEnvironmentVariable("RABBITMQ_HOST"),
                UserName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME"),
                Password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD")
            };

            var connection = factory.CreateConnection();
            _channel = connection.CreateModel();

            _channel.QueueDeclare(
                queue: "meetspace.password-reset",
                durable: true,
                exclusive: false,
                autoDelete: false);

            _channel.QueueDeclare(
    queue: "meetspace.booking-status",
    durable: true,
    exclusive: false,
    autoDelete: false);

            _channel.QueueDeclare(
    queue: "meetspace.booking-reminder",
    durable: true,
    exclusive: false,
    autoDelete: false);

        }
        public Task StartConsumingAsync(CancellationToken cancellationToken)
        {
            var consumer = new EventingBasicConsumer(_channel);

            _logger.LogInformation("STARTING CONSUMER...");

            consumer.Received += async (model, ea) =>
            {
                var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                var message = JsonConvert.DeserializeObject<PasswordResetRequested>(json);

                await _emailService.SendPasswordResetEmailAsync(message);

                _channel.BasicAck(ea.DeliveryTag, false);
            };

            _channel.BasicConsume("meetspace.password-reset", false, consumer);

            var bookingConsumer = new EventingBasicConsumer(_channel);

            bookingConsumer.Received += async (model, ea) =>
            {
                try
                {
                    var json = Encoding.UTF8.GetString(ea.Body.ToArray());

                    _logger.LogInformation("BOOKING MESSAGE RECEIVED: {json}", json);

                    var message = JsonConvert.DeserializeObject<BookingStatusChangedMessage>(json);

                    if (message == null)
                    {
                        _logger.LogWarning("Message null");
                        return;
                    }

                    var client = new HttpClient();

                    var url =
    $"{Environment.GetEnvironmentVariable("API_BASE_URL")}/api/notifications/send";

                    var payload = JsonConvert.SerializeObject(message);
                    var content = new StringContent(payload, Encoding.UTF8, "application/json");

                    var response = await client.PostAsync(url, content);

                    _logger.LogInformation("Notification API response: {status}", response.StatusCode);

                    _channel.BasicAck(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "ERROR IN CONSUMER");
                }
            };

            var reminderConsumer = new EventingBasicConsumer(_channel);

            reminderConsumer.Received += async (model, ea) =>
            {
                try
                {
                    var json = Encoding.UTF8.GetString(ea.Body.ToArray());

                    _logger.LogInformation("REMINDER MESSAGE RECEIVED: {json}", json);

                    var message = JsonConvert.DeserializeObject<BookingReminderMessage>(json);

                    if (message == null)
                        return;

                    var client = new HttpClient();

                    var url =
    $"{Environment.GetEnvironmentVariable("API_BASE_URL")}/api/notifications/reminder";

                    var payload = JsonConvert.SerializeObject(message);

                    var content = new StringContent(
                        payload,
                        Encoding.UTF8,
                        "application/json");

                    var response = await client.PostAsync(url, content);

                    _logger.LogInformation(
                        "Reminder API response: {status}",
                        response.StatusCode);

                    _channel.BasicAck(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "ERROR IN REMINDER CONSUMER");
                }
            };

            _channel.BasicConsume(
                "meetspace.booking-reminder",
                false,
                reminderConsumer);

            _channel.BasicConsume("meetspace.booking-status", false, bookingConsumer);

            return Task.CompletedTask;
        }

        public void Dispose()
        {
            _channel?.Dispose();
        }
    }

}
