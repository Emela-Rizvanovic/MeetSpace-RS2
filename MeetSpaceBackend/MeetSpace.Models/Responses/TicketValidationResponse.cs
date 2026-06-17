namespace MeetSpace.Models.Responses
{
    public class TicketValidationResponse
    {
        public bool IsValid { get; set; }
        public string Message { get; set; } = string.Empty;
        public int? BookingId { get; set; }
        public string? Username { get; set; }
        public string? UserFullName { get; set; }
        public string? SpaceName { get; set; }
        public string? FacilityAddress { get; set; }
        public string? BookingStatus { get; set; }
        public string? PaymentStatus { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
    }
}