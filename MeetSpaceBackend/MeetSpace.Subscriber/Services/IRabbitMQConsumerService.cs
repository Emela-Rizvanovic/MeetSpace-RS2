namespace MeetSpace.Subscriber.Services
{
    public interface IRabbitMQConsumerService : IDisposable
    {
        Task StartConsumingAsync(CancellationToken cancellationToken);
    }
}
