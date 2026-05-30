using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class UserLoginRequest
    {
        [Required(ErrorMessage = "Username is required.")]
        [MinLength(4, ErrorMessage = "Username must be at least 4 characters.")]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Password is required.")]
        public string Password { get; set; } = string.Empty;
    }
}
