using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace MeetSpace.Models.Requests
{
    public class UserInsertRequest
    {
        public int RoleId { get; set; }

        [Required(ErrorMessage = "First name is required.")]
        [MinLength(2, ErrorMessage = "First name must have at least 2 characters.")]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Last name is required.")]
        [MinLength(2, ErrorMessage = "Last name must have at least 2 characters.")]
        public string LastName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email is required.")]
        [RegularExpression(@"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
        ErrorMessage = "Email must be in a valid format, e.g. example@mail.com.")]
        public string Email { get; set; } = string.Empty;


        [Required(ErrorMessage = "Username is required.")]
        [MinLength(4, ErrorMessage = "Username must be at least 4 characters.")]
        public string Username {  get; set; } = string.Empty;

        [Required(ErrorMessage = "Password is required.")]
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters.")]
        [RegularExpression(@"^(?=.*[A-Z])(?=.*\d).{6,}$",
        ErrorMessage = "Password must contain 1 uppercase letter and 1 number.")]
        public string Password { get; set; } = string.Empty;

        [Phone(ErrorMessage = "Enter valid phone number.")]
        [RegularExpression(@"^\+?[0-9 ]{8,15}$",
        ErrorMessage = "Phone must contain only digits, min 8 - max 15.")]
        public string? PhoneNumber { get; set; }
        public IFormFile? ProfileImageUrl { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
