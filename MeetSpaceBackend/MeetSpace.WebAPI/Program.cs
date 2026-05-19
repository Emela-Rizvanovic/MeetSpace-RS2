using AutoMapper;
using MeetSpace.API.Helpers;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using MeetSpace.Services.Mapping;
using MeetSpace.Services.Security;
using MeetSpace.Services.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.Text;

internal class Program
{
    private static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        Stripe.StripeConfiguration.ApiKey = builder.Configuration["Stripe:SecretKey"];

        // DbContext
        builder.Services.AddDbContext<MeetSpaceDbContext>(options =>
            options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))
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
        var jwtSettings = builder.Configuration.GetSection("Jwt");
        var key = Encoding.UTF8.GetBytes(jwtSettings["Key"]);

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
                ValidIssuer = jwtSettings["Issuer"],
                ValidAudience = jwtSettings["Audience"],
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

        var app = builder.Build();

        // Configure the HTTP request pipeline
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        //app.UseHttpsRedirection();


        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();

        app.MapHub<MeetSpace.API.Hubs.NotificationHub>("/notificationHub");

        app.UseExceptionHandler(errorApp =>
        {
            errorApp.Run(async context =>
            {
                var exceptionHandlerPathFeature =
                    context.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerPathFeature>();

                var exception = exceptionHandlerPathFeature?.Error;

                if (exception is ApplicationException)
                {
                    context.Response.StatusCode = StatusCodes.Status400BadRequest;
                    await context.Response.WriteAsync(exception.Message);
                }

                if (exception is UnauthorizedAccessException)
                {
                    context.Response.StatusCode = StatusCodes.Status403Forbidden;
                    await context.Response.WriteAsync(exception.Message);
                    return;
                }
            });
        });

        app.Run();
    }
}
