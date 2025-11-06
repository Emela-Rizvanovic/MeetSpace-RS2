using MeetSpace.Models.Entities;
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
        public DbSet<SpaceWorkingHours> SpaceWorkingHours { get; set; }
        public DbSet<SpaceBlockedDate> SpaceBlockedDates { get; set; }
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
        public DbSet<QRCode> QRCodes { get; set; }
        public DbSet<Report> Reports { get; set; }
        public DbSet<ReportType> ReportTypes { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<RecommendationLog> RecommendationLogs { get; set; }

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
