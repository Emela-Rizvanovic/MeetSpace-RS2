using MeetSpace.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using RabbitMQ.Client;
using System;
using System.Text;
using System.Threading.Tasks;
using IModel = RabbitMQ.Client.IModel;

namespace MeetSpace.Services.Services
{
    public class RabbitMQService : IRabbitMQService, IDisposable
    {
        private readonly IConnection? _connection;
        private readonly IModel? _channel;
        private readonly ILogger<RabbitMQService> _logger;

        public RabbitMQService(IConfiguration config, ILogger<RabbitMQService> logger)
        {
            _logger = logger;

            try
            {
                var factory = new ConnectionFactory
                {
                    HostName = Environment.GetEnvironmentVariable("RABBITMQ_HOST"),
                    UserName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME"),
                    Password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD")
                };

                _connection = factory.CreateConnection();
                _channel = _connection.CreateModel();

                _channel.QueueDeclare(
                    queue: "meetspace.password-reset",
                    durable: true,
                    exclusive: false,
                    autoDelete: false);

                _logger.LogInformation("RabbitMQ connection established successfully.");
            }
            catch (Exception ex)
            {
                // Ako RabbitMQ nije dostupan, samo loguj i nastavi
                _logger.LogWarning(ex, "RabbitMQ unavailable, continuing without queue.");
                _connection = null;
                _channel = null;
            }
        }

        public Task PublishAsync<T>(T message, string queueName) where T : class
        {
            if (_channel == null)
            {
                _logger.LogWarning("RabbitMQ channel not available, skipping publish for {MessageType}", typeof(T).Name);
                return Task.CompletedTask;
            }

            var json = JsonConvert.SerializeObject(message);
            var body = Encoding.UTF8.GetBytes(json);

            var props = _channel.CreateBasicProperties();
            props.Persistent = true;

            _channel.BasicPublish(
                exchange: "",
                routingKey: queueName,
                basicProperties: props,
                body: body);

            return Task.CompletedTask;
        }

        public void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();
        }
    }
}
