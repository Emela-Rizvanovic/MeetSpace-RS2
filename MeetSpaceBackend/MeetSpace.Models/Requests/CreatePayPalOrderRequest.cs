using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class CreatePayPalOrderRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Space is required. Select a valid space.")]
        public int SpaceId { get; set; }

        [Required(ErrorMessage = "Start time is required.")]
        public DateTime StartTime { get; set; }

        [Required(ErrorMessage = "End time is required.")]
        public DateTime EndTime { get; set; }

        public List<BookingAmenityInsertRequest> Amenities { get; set; } = new();
    }
}