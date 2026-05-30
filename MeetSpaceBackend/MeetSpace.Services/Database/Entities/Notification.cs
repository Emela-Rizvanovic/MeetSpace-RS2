namespace MeetSpace.Models.Entities
{
    public class Notification
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int NotificationTypeId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public bool IsRead { get; set; } = false;
        public int? RelatedBookingId { get; set; }
        public Booking? RelatedBooking { get; set; }


        public User? User { get; set; }
        public NotificationType? NotificationType { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
