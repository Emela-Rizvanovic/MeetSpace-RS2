using MeetSpace.Models.Enums;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MeetSpace.Models.Requests
{
    public class BookingInsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Space is required. Select a valid space.")]
        public int SpaceId { get; set; }

        public int? UserId { get; set; }


        [JsonIgnore]
        public PaymentStatusEnum? InternalPaymentStatus { get; set; }

        [Required(ErrorMessage = "Start time is required.")]
        public DateTime StartTime { get; set; }

        [Required(ErrorMessage = "End time is required.")]
        public DateTime EndTime { get; set; }

        public List<BookingAmenityInsertRequest>? Amenities { get; set; }
    }
}