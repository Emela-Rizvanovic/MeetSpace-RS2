using MeetSpace.Subscriber;
using MeetSpace.Subscriber.Services;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddHostedService<Worker>();
builder.Services.AddSingleton<IEmailService, EmailService>();
builder.Services.AddSingleton<IRabbitMQConsumerService, RabbitMQConsumerService>();
builder.Services.AddHostedService<MessageConsumerHostedService>();


var host = builder.Build();
host.Run();
