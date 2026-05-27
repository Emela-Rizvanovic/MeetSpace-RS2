using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class RejectRequest
    {
        [Required(ErrorMessage = "Rejection reason is required.")]
        [StringLength(500, MinimumLength = 5, ErrorMessage = "Rejection reason must contain 5-500 characters.")]
        public string Reason { get; set; } = string.Empty;
    }
}