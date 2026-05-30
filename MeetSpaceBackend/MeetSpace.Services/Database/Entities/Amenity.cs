namespace MeetSpace.Models.Entities
{
    public class Amenity
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public int AmenityCategoryId { get; set; }

        public AmenityCategory? AmenityCategory { get; set; }
        public ICollection<SpaceAmenity> SpaceAmenities { get; set; } = new HashSet<SpaceAmenity>();
        public ICollection<BookingAmenity> BookingAmenities { get; set; } = new HashSet<BookingAmenity>();
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
