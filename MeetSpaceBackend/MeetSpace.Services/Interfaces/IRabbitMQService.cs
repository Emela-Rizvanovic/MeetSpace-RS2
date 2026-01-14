using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Interfaces
{
    public interface IRabbitMQService
    {
        Task PublishAsync<T>(T message, string queueName) where T : class;
    }
}
