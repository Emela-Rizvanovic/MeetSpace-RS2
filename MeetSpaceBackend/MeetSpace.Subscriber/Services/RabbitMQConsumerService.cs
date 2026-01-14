using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using Newtonsoft.Json;
using MeetSpace.Models.Messages;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
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
                HostName = config["RabbitMQ:HostName"],
                UserName = config["RabbitMQ:UserName"],
                Password = config["RabbitMQ:Password"]
            };

            var connection = factory.CreateConnection();
            _channel = connection.CreateModel();

            _channel.QueueDeclare(
                queue: "meetspace.password-reset",
                durable: true,
                exclusive: false,
                autoDelete: false);
        }

        public Task StartConsumingAsync(CancellationToken cancellationToken)
        {
            var consumer = new EventingBasicConsumer(_channel);

            consumer.Received += async (model, ea) =>
            {
                var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                var message = JsonConvert.DeserializeObject<PasswordResetRequested>(json);

                await _emailService.SendPasswordResetEmailAsync(message);

                _channel.BasicAck(ea.DeliveryTag, false);
            };

            _channel.BasicConsume("meetspace.password-reset", false, consumer);

            return Task.CompletedTask;
        }

        public void Dispose()
        {
            _channel?.Dispose();
        }
    }

}
