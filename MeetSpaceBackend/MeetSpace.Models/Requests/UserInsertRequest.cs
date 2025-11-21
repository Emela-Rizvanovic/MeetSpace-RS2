using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class UserInsertRequest
    {
        public int RoleId { get; set; }

        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;

        public string Username {  get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;

        public string? PhoneNumber { get; set; }
        public IFormFile? ProfileImageUrl { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
