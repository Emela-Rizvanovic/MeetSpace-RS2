using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class PaymentMethodInsertRequest
    {
        [Required(ErrorMessage = "Payment method name is required.")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Payment method name must contain 2-50 characters.")]
        public string Name { get; set; } = string.Empty;
    }
}