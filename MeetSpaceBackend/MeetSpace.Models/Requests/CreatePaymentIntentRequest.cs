using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class CreatePaymentIntentRequest
    {
        [Range(0.01, 100000, ErrorMessage = "Amount must be a valid number greater than 0, e.g. 25.50.")]
        public decimal Amount { get; set; }

        [Required(ErrorMessage = "Currency is required.")]
        [RegularExpression(@"^[a-zA-Z]{3}$", ErrorMessage = "Currency must be a valid 3-letter code, e.g. BAM or EUR.")]
        public string Currency { get; set; } = "bam";
    }
}