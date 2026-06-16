namespace MeetSpace.Models.Messages
{
    public class BookingReminderMessage
    {
        public int UserId { get; set; }

        public string SpaceName { get; set; } = string.Empty;

        public DateTime StartTime { get; set; }
        public int? RelatedBookingId { get; set; }
    }

}