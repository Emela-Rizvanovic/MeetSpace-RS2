using MeetSpace.Models.Entities;
using MeetSpace.Services.Database.Entities;
using Microsoft.EntityFrameworkCore;

namespace MeetSpace.Services.Database
{
    public class MeetSpaceDbContext : DbContext
    {
        public MeetSpaceDbContext(DbContextOptions<MeetSpaceDbContext> options)
            : base(options) { }

        // DbSet-ovi za sve entitete
        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<Country> Countries { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Facility> Facilities { get; set; }
        public DbSet<Space> Spaces { get; set; }
        public DbSet<SpaceType> SpaceTypes { get; set; }
        public DbSet<SpaceImage> SpaceImages { get; set; }
        public DbSet<Amenity> Amenities { get; set; }
        public DbSet<AmenityCategory> AmenityCategories { get; set; }
        public DbSet<SpaceAmenity> SpaceAmenities { get; set; }
        public DbSet<Booking> Bookings { get; set; }
        public DbSet<BookingAmenity> BookingAmenities { get; set; }
        public DbSet<BookingStatus> BookingStatuses { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<PaymentIntent> PaymentIntents { get; set; }
        public DbSet<PaymentMethod> PaymentMethods { get; set; }
        public DbSet<PaymentStatus> PaymentStatuses { get; set; }
        public DbSet<Favorite> Favorites { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<NotificationType> NotificationTypes { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<RecommendationLog> RecommendationLogs { get; set; }
        public DbSet<PasswordReset> PasswordResets { get; set; }
        public DbSet<RevokedToken> RevokedTokens { get; set; }
        public DbSet<BookingAuditLog> BookingAuditLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Composite key za many-to-many tabele
            modelBuilder.Entity<Favorite>()
                .HasKey(f => new { f.UserId, f.SpaceId });

            modelBuilder.Entity<SpaceAmenity>()
                .HasKey(sa => new { sa.SpaceId, sa.AmenityId });

            // Relacije za BookingAmenity
            modelBuilder.Entity<BookingAmenity>()
                .HasOne(ba => ba.Booking)
                .WithMany(b => b.BookingAmenities)
                .HasForeignKey(ba => ba.BookingId);

            modelBuilder.Entity<BookingAmenity>()
                .HasOne(ba => ba.Amenity)
                .WithMany(a => a.BookingAmenities)
                .HasForeignKey(ba => ba.AmenityId);

            // Decimal preciznosti
            modelBuilder.Entity<Booking>()
                .Property(b => b.TotalPrice)
                .HasPrecision(18,2);

            modelBuilder.Entity<BookingAmenity>()
                .Property(ba => ba.Price)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Payment>()
                .Property(p => p.Amount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Payment>()
    .HasIndex(p => p.ExternalTransactionId)
    .IsUnique()
    .HasFilter("[ExternalTransactionId] IS NOT NULL");

            modelBuilder.Entity<PaymentIntent>()
                .Property(pi => pi.Amount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Space>()
                .Property(s => s.PricePerHour)
                .HasPrecision(18, 2);

            // Rješavanje multiple cascade paths za Payments
            modelBuilder.Entity<Payment>()
                .HasOne(p => p.User)
                .WithMany()
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.Booking)
                .WithMany(b => b.Payments)
                .HasForeignKey(p => p.BookingId)
                .OnDelete(DeleteBehavior.Cascade);

               modelBuilder.Entity<Payment>()
                 .HasOne(p => p.PaymentIntent)
                 .WithMany(pi => pi.Payments)
                 .HasForeignKey(p => p.PaymentIntentId)
                 .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.PaymentMethod)
                .WithMany(pm => pm.Payments)
                .HasForeignKey(p => p.PaymentMethodId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.PaymentStatus)
                .WithMany(ps => ps.Payments)
                .HasForeignKey(p => p.PaymentStatusId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Booking>()
    .HasOne(b => b.PaymentStatus)
    .WithMany()
    .HasForeignKey(b => b.PaymentStatusId)
    .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Booking>()
    .Property(b => b.PaymentStatusId)
    .HasDefaultValue(1);

            modelBuilder.Entity<BookingAuditLog>()
    .HasOne(x => x.Admin)
    .WithMany()
    .HasForeignKey(x => x.AdminId)
    .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<BookingAuditLog>()
    .HasOne(x => x.Booking)
    .WithMany()
    .HasForeignKey(x => x.BookingId)
    .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Review>()
            .HasIndex(r => new { r.UserId, r.SpaceId })
            .IsUnique();

            modelBuilder.Entity<Review>()
            .Property(r => r.Rating)
            .IsRequired();

            modelBuilder.Entity<Review>()
            .ToTable(t =>
            t.HasCheckConstraint(
            "CK_Review_Rating",
            "[Rating] >= 1 AND [Rating] <= 5"));

            modelBuilder.Entity<RevokedToken>()
    .HasIndex(x => x.Jti)
    .IsUnique();

        }

        public override int SaveChanges()
        {
            UpdateAuditFields();
            return base.SaveChanges();
        }

        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            UpdateAuditFields();
            return await base.SaveChangesAsync(cancellationToken);
        }

        private void UpdateAuditFields()
        {
            var entries = ChangeTracker.Entries()
                .Where(e => e.Entity is { } && (e.State == EntityState.Added || e.State == EntityState.Modified));

            foreach (var entry in entries)
            {
                var entity = entry.Entity;
                var now = DateTime.UtcNow;
                var type = entity.GetType();

                if (entry.State == EntityState.Added && type.GetProperty("CreatedAt") != null)
                    type.GetProperty("CreatedAt")?.SetValue(entity, now);

                if (type.GetProperty("UpdatedAt") != null)
                    type.GetProperty("UpdatedAt")?.SetValue(entity, now);
            }
        }
    }
}
