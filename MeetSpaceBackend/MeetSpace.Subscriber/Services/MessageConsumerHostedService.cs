using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Subscriber.Services
{
    public class MessageConsumerHostedService : BackgroundService
    {
        private readonly IRabbitMQConsumerService _consumer;

        public MessageConsumerHostedService(IRabbitMQConsumerService consumer)
        {
            _consumer = consumer;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await _consumer.StartConsumingAsync(stoppingToken);
        }
    }

}
