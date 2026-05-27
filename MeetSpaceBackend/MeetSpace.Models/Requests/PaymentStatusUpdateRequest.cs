using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class PaymentStatusUpdateRequest
    {
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Payment status name must contain 2-50 characters.")]
        public string? Name { get; set; }
    }
}