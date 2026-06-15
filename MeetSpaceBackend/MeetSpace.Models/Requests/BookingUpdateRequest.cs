using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class BookingUpdateRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Space must be a valid selected space.")]
        public int? SpaceId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "User must be a valid selected user.")]
        public int? UserId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Booking status must be a valid selected status.")]
        public int? BookingStatusId { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public List<BookingAmenityInsertRequest>? Amenities { get; set; }
    }
}