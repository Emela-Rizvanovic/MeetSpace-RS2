using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class BookingStatusUpdateRequest
    {
        public string? Name { get; set; } = string.Empty;
    }
}
