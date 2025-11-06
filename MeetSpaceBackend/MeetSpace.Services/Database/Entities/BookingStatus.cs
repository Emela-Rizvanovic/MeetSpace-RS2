namespace MeetSpace.Models.Entities
{
    public class BookingStatus
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public ICollection<Booking> Bookings { get; set; } = new HashSet<Booking>();
    }
}
