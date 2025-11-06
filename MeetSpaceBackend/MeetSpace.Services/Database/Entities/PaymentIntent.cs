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

        public ICollection<Payment> Payments { get; set; } = new HashSet<Payment>();
    }
}
