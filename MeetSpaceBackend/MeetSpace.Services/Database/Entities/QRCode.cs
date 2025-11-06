namespace MeetSpace.Models.Entities
{
    public class QRCode
    {
        public int Id { get; set; }
        public int BookingId { get; set; }
        public string QRCodeData { get; set; } = string.Empty;
        public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;

        public Booking? Booking { get; set; }
    }
}
