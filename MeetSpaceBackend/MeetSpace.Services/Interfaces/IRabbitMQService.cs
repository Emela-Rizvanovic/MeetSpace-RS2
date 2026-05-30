namespace MeetSpace.Services.Interfaces
{
    public interface IRabbitMQService
    {
        Task PublishAsync<T>(T message, string queueName) where T : class;
    }
}
