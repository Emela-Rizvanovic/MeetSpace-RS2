using System.Security.AccessControl;

namespace MeetSpace.Models.Entities
{
    public class Space
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal PricePerHour { get; set; }
        public int Capacity { get; set; }
        public int FacilityId { get; set; }
        public int SpaceTypeId { get; set; }

        // Navigacija
        public Facility? Facility { get; set; }
        public SpaceType? SpaceType { get; set; }
        public ICollection<SpaceImage> Images { get; set; } = new HashSet<SpaceImage>();
        public ICollection<SpaceWorkingHours> WorkingHours { get; set; } = new HashSet<SpaceWorkingHours>();
        public ICollection<SpaceBlockedDate> BlockedDates { get; set; } = new HashSet<SpaceBlockedDate>();
        public ICollection<SpaceAmenity> SpaceAmenities { get; set; } = new HashSet<SpaceAmenity>();
        public ICollection<Booking> Bookings { get; set; } = new HashSet<Booking>();

        // Audit polja
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
