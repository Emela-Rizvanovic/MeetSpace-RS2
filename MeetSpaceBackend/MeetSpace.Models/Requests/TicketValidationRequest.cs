using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class TicketValidationRequest
    {
        [Required(ErrorMessage = "QR ticket data is required.")]
        public string QrData { get; set; } = string.Empty;
    }
}