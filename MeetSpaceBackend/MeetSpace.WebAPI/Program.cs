using AutoMapper;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using MeetSpace.Services.Mapping;
using MeetSpace.Services.Security;
using MeetSpace.Services.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

internal class Program
{
    private static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

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
        builder.Services.AddScoped<IReportTypeService, ReportTypeService>();
        builder.Services.AddScoped<IRoleService, RoleService>();
        builder.Services.AddScoped<IUserService, UserService>();
        builder.Services.AddScoped<IPasswordHasher, Pbkdf2PasswordHasher>();
        builder.Services.AddScoped<IBlobService, BlobService>();


        // Registracija AutoMappera
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<SpaceProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<FacilityProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<SpaceTypeProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<AmenityCategoryProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<AmenityProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<ReportTypeProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<RoleProfile>());
        builder.Services.AddAutoMapper(cfg => cfg.AddProfile<UserProfile>());


        // Add controllers
        builder.Services.AddControllers();

        // Swagger/OpenAPI
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen();

        var app = builder.Build();

        // Configure the HTTP request pipeline
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        app.UseHttpsRedirection();

        // Za sada auth možemo ignorisati dok testiramo
        // app.UseAuthorization();

        app.MapControllers();

        app.Run();
    }
}
