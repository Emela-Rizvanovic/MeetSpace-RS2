using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class BookingInsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Space is required. Select a valid space.")]
        public int SpaceId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "User is required. Select a valid user.")]
        public int UserId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Booking status is required. Select a valid booking status.")]
        public int BookingStatusId { get; set; }

        [Required(ErrorMessage = "Start time is required.")]
        public DateTime StartTime { get; set; }

        [Required(ErrorMessage = "End time is required.")]
        public DateTime EndTime { get; set; }

        public List<BookingAmenityInsertRequest>? Amenities { get; set; }
    }
}