using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class UserUpdateRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Role must be a valid selected role.")]
        public int? RoleId { get; set; }

        [StringLength(50, MinimumLength = 4, ErrorMessage = "Username must contain 4-50 characters.")]
        public string? Username { get; set; }

        [StringLength(100, MinimumLength = 6, ErrorMessage = "Password must contain at least 6 characters.")]
        [RegularExpression(@"^(?=.*[A-Z])(?=.*\d).{6,}$", ErrorMessage = "Password must contain at least 6 characters, one uppercase letter and one number.")]
        public string? Password { get; set; }

        [StringLength(100, MinimumLength = 6, ErrorMessage = "Current password must contain at least 6 characters.")]
        public string? CurrentPassword { get; set; }

        [StringLength(50, MinimumLength = 2, ErrorMessage = "First name must contain 2-50 characters.")]
        public string? FirstName { get; set; }

        [StringLength(50, MinimumLength = 2, ErrorMessage = "Last name must contain 2-50 characters.")]
        public string? LastName { get; set; }

        [EmailAddress(ErrorMessage = "Email must be in a valid format, e.g. example@mail.com.")]
        public string? Email { get; set; }

        [RegularExpression(@"^\+?[0-9 ]{8,15}$", ErrorMessage = "Phone number must contain 8-15 digits, optionally starting with +. Example: +387 61 123 456.")]
        public string? PhoneNumber { get; set; }

        public IFormFile? ProfileImageUrl { get; set; }

        public bool? IsActive { get; set; }
    }
}