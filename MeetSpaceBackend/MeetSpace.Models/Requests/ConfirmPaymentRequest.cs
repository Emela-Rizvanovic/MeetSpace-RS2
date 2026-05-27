using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class ConfirmPaymentRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Space is required. Select a valid space.")]
        public int SpaceId { get; set; }

        [Required(ErrorMessage = "Start time is required.")]
        public DateTime StartTime { get; set; }

        [Required(ErrorMessage = "End time is required.")]
        public DateTime EndTime { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Payment intent is required. Provide a valid payment intent id.")]
        public int PaymentIntentId { get; set; }

        public List<AmenityBookingRequest> Amenities { get; set; } = new();
    }

    public class AmenityBookingRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Amenity is required. Select a valid amenity.")]
        public int AmenityId { get; set; }

        [Range(1, 100000, ErrorMessage = "Amenity quantity must be a whole number greater than 0.")]
        public int Quantity { get; set; }
    }
}