using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class PaymentMethodUpdateRequest
    {
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Payment method name must contain 2-50 characters.")]
        public string? Name { get; set; }
    }
}