namespace MeetSpace.Models.Requests
{
    public class ConfirmPaymentRequest
    {
        public int SpaceId { get; set; }

        public DateTime StartTime { get; set; }

        public DateTime EndTime { get; set; }

        public int PaymentIntentId { get; set; }

        public List<AmenityBookingRequest> Amenities { get; set; } = new();
    }

    public class AmenityBookingRequest
    {
        public int AmenityId { get; set; }
        public int Quantity { get; set; }
    }
}