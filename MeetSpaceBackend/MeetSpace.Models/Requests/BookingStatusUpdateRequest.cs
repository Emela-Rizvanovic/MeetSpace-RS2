using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class BookingStatusUpdateRequest
    {
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Booking status name must contain 2-50 characters.")]
        public string? Name { get; set; }
    }
}