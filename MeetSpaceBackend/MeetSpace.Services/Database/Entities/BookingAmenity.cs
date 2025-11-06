namespace MeetSpace.Models.Entities
{
    public class BookingAmenity
    {
        public int Id { get; set; }
        public int BookingId { get; set; }
        public int AmenityId { get; set; }
        public int Quantity { get; set; }
        public decimal Price { get; set; }

        public Booking? Booking { get; set; }
        public Amenity? Amenity { get; set; }
    }
}
