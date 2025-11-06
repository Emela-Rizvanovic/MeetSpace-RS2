namespace MeetSpace.Models.Entities
{
    public class PaymentMethod
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public ICollection<Payment> Payments { get; set; } = new HashSet<Payment>();
    }
}
