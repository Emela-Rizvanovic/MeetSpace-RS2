using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Email must be in a valid format, e.g. example@mail.com.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Reset code is required.")]
        [StringLength(10, MinimumLength = 4, ErrorMessage = "Reset code must contain 4-10 characters.")]
        public string ResetCode { get; set; } = string.Empty;

        [Required(ErrorMessage = "New password is required.")]
        [MinLength(6, ErrorMessage = "New password must contain at least 6 characters.")]
        [RegularExpression(@"^(?=.*[A-Z])(?=.*\d).{6,}$", ErrorMessage = "New password must contain at least 6 characters, one uppercase letter and one number.")]
        public string NewPassword { get; set; } = string.Empty;
    }
}