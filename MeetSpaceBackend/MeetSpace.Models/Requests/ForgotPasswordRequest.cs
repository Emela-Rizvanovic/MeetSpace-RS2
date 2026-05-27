using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class ForgotPasswordRequest
    {
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Email must be in a valid format, e.g. example@mail.com.")]
        public string Email { get; set; } = string.Empty;
    }
}