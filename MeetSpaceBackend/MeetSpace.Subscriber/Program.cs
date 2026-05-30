using MeetSpace.Subscriber.Services;
using DotNetEnv;

var builder = Host.CreateApplicationBuilder(args);
Env.Load(Path.Combine(Directory.GetCurrentDirectory(), ".env"));
builder.Services.AddHttpClient();
builder.Services.AddSingleton<IEmailService, EmailService>();
builder.Services.AddSingleton<IRabbitMQConsumerService, RabbitMQConsumerService>();
builder.Services.AddHostedService<MessageConsumerHostedService>();


var host = builder.Build();
host.Run();
