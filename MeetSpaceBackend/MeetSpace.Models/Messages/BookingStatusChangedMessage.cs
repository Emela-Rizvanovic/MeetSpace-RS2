using MeetSpace.Models.Enums;

namespace MeetSpace.Models.Messages
{
    public class BookingStatusChangedMessage
    {
        public int UserId { get; set; }
        public string SpaceName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public bool IsApproved { get; set; }
        public string? Reason { get; set; }
        public bool IsCancellation { get; set; }
        public int? RelatedBookingId { get; set; }
        public NotificationTypeEnum? NotificationType { get; set; }
        public string? ActorUsername { get; set; }
        public bool RequiresManualPaymentReview { get; set; }
    }
}