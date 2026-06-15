namespace MeetSpace.Models.Responses
{
    public class PaymentIntentResponse
    {
        public string ClientSecret { get; set; } = string.Empty;
        public int PaymentIntentId { get; set; }
        public decimal Amount { get; set; }
    }
}