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
        public bool IsActive { get; set; } = true;
        public DateTime? ArchivedAt { get; set; }
        public Facility? Facility { get; set; }
        public SpaceType? SpaceType { get; set; }
        public ICollection<SpaceImage> Images { get; set; } = new HashSet<SpaceImage>();
        public ICollection<SpaceAmenity> SpaceAmenities { get; set; } = new HashSet<SpaceAmenity>();
        public ICollection<Booking> Bookings { get; set; } = new HashSet<Booking>();
        public ICollection<Review> Reviews { get; set; } = new HashSet<Review>();
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
