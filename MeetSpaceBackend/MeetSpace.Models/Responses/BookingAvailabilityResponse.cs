using MeetSpace.Models.Constants;

namespace MeetSpace.Models.Responses
{
    public class BookingAvailabilityResponse
    {
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string Status { get; set; } = AvailabilityStatuses.Busy;
    }
}