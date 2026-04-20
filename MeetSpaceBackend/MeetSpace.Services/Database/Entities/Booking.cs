namespace MeetSpace.Models.Entities
{
    public class Booking
    {
        public int Id { get; set; }
        public int SpaceId { get; set; }
        public int UserId { get; set; }
        public int BookingStatusId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal TotalPrice { get; set; }
        public string? RejectionReason { get; set; }
        public int PaymentStatusId { get; set; }
        public PaymentStatus PaymentStatus { get; set; }

        // Navigacija
        public Space? Space { get; set; }
        public User? User { get; set; }
        public BookingStatus? BookingStatus { get; set; }
        public ICollection<BookingAmenity> BookingAmenities { get; set; } = new HashSet<BookingAmenity>();
        public ICollection<Payment> Payments { get; set; } = new HashSet<Payment>();

        // Audit
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
