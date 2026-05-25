using AutoMapper;
using DotNetEnv;
using MeetSpace.API.Helpers;
using MeetSpace.Models.Exceptions;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using MeetSpace.Services.Mapping;
using MeetSpace.Services.Security;
using MeetSpace.Services.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Text.Json;

internal class Program
{
    private static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        Env.Load(Path.Combine(Directory.GetCurrentDirectory(), ".env"));

        Stripe.StripeConfiguration.ApiKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");

        // DbContext
        builder.Services.AddDbContext<MeetSpaceDbContext>(options =>
            options.UseSqlServer(Environment.GetEnvironmentVariable("DB_CONNECTION"))
        );

        // Registracija servisa
        builder.Services.AddScoped<ISpaceService, SpaceService>();
        builder.Services.AddScoped<IFacilityService, FacilityService>();
        builder.Services.AddScoped<ISpaceTypeService, SpaceTypeService>();
        builder.Services.AddScoped<IAmenityCategoryService, AmenityCategoryService>();
        builder.Services.AddScoped<IAmenityService, AmenityService>();
        builder.Services.AddScoped<IRoleService, RoleService>();
        builder.Services.AddScoped<IUserService, UserService>();
        builder.Services.AddScoped<IPasswordHasher, Pbkdf2PasswordHasher>();
        builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
        builder.Services.AddScoped<IBlobService, BlobService>();
        builder.Services.AddSingleton<IRabbitMQService, RabbitMQService>();
        builder.Services.AddScoped<IFavoriteService, FavoriteService>();
        builder.Services.AddScoped<IReviewService, ReviewService>();
        builder.Services.AddScoped<IBookingService, BookingService>();
        builder.Services.AddScoped<IBookingStatusService, BookingStatusService>();
        builder.Services.AddScoped<IRecommendationService, RecommendationService>();
        builder.Services.AddScoped<IRevenueService, RevenueService>();
        builder.Services.AddScoped<ICountryService, CountryService>();
        builder.Services.AddScoped<ICityService, CityService>();
        builder.Services.AddScoped<IPaymentMethodService, PaymentMethodService>();
        builder.Services.AddScoped<IPaymentStatusService, PaymentStatusService>();
        builder.Services.AddScoped<INotificationService, NotificationService>();
        builder.Services.AddScoped<IPaymentService, PaymentService>();
        builder.Services.AddScoped<IPayPalService, PayPalService>();


        // Registracija AutoMappera
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<SpaceProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<FacilityProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<SpaceTypeProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<AmenityCategoryProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<AmenityProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<RoleProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<UserProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<BookingProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<BookingStatusProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<ReviewProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<CountryProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<CityProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<PaymentMethodProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<PaymentStatusProfile>());

        // JWT konfiguracija
        var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY");
        var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER");
        var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE");

        var key = Encoding.UTF8.GetBytes(jwtKey!);

        builder.Services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.RequireHttpsMetadata = false;
            options.SaveToken = true;
            options.Configuration = new Microsoft.IdentityModel.Protocols.OpenIdConnect.OpenIdConnectConfiguration();
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = jwtIssuer,
                ValidAudience = jwtAudience,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ClockSkew = TimeSpan.Zero
            };
        });

        builder.Services.AddAuthorization();


        // Add controllers
        builder.Services.AddControllers();

        builder.Services.AddSignalR();

        builder.Services.AddSingleton<IUserIdProvider, CustomUserIdProvider>();

        // Swagger/OpenAPI
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new() { Title = "MeetSpace API", Version = "v1" });

            c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Name = "Authorization",
                Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
                In = Microsoft.OpenApi.Models.ParameterLocation.Header,
                Description = "Enter 'Bearer' [space] and then your token."
            });

            c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
        });

        builder.Services.AddHttpContextAccessor();
        builder.Services.AddHttpClient();

        builder.Services.AddCors(options =>
        {
            options.AddPolicy("MeetSpaceCors", policy =>
            {
                policy.WithOrigins(
                        "http://localhost:5245",
                        "https://localhost:7256",
                        "http://localhost:6269",
                        "http://10.0.2.2:5245"
                    )
                    .AllowAnyHeader()
                    .AllowAnyMethod()
                    .AllowCredentials();
            });
        });

        var app = builder.Build();

        // Configure the HTTP request pipeline
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        //app.UseHttpsRedirection();

        app.UseCors("MeetSpaceCors");


        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();

        app.MapHub<MeetSpace.API.Hubs.NotificationHub>("/notificationHub");

        app.UseExceptionHandler(errorApp =>
        {
            errorApp.Run(async context =>
            {
                var exceptionHandlerPathFeature =
                    context.Features.Get<IExceptionHandlerPathFeature>();

                var exception = exceptionHandlerPathFeature?.Error;

                var logger = context.RequestServices
    .GetRequiredService<ILogger<Program>>();

                context.Response.ContentType = "application/json";

                if (exception is BusinessException)
                {

                    logger.LogWarning(exception, "Business exception occurred while processing request.");

                    context.Response.StatusCode = StatusCodes.Status400BadRequest;

                    await context.Response.WriteAsync(JsonSerializer.Serialize(new
                    {
                        message = exception.Message
                    }));

                    return;
                }

                if (exception is NotFoundException)
                {
                    logger.LogWarning(exception, "Requested resource was not found.");

                    context.Response.StatusCode = StatusCodes.Status404NotFound;

                    await context.Response.WriteAsync(JsonSerializer.Serialize(new
                    {
                        message = exception.Message
                    }));

                    return;
                }

                if (exception is UnauthorizedAccessException)
                {
                    logger.LogWarning(exception, "Unauthorized access attempt.");

                    context.Response.StatusCode = StatusCodes.Status403Forbidden;

                    await context.Response.WriteAsync(JsonSerializer.Serialize(new
                    {
                        message = "Access denied."
                    }));

                    return;
                }

                logger.LogError(exception, "Unhandled exception occurred while processing request.");

                context.Response.StatusCode = StatusCodes.Status500InternalServerError;

                await context.Response.WriteAsync(JsonSerializer.Serialize(new
                {
                    message = "An error occurred while processing your request."
                }));
            });
        });

        app.Run();
    }
}
