namespace MeetSpace.Models.Entities
{
    public class PaymentIntent
    {
        public int Id { get; set; }
        public string StripePaymentIntentId { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "BAM";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsCompleted { get; set; } = false;

        public int UserId { get; set; }
        public int SpaceId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string AmenitiesSnapshotJson { get; set; } = "[]";
        public string Provider { get; set; } = "Stripe";
        public string? ProviderOrderId { get; set; }
        public string Status { get; set; } = "Created";
        public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddMinutes(30);
        public ICollection<Payment> Payments { get; set; } = new HashSet<Payment>();
    }
}
