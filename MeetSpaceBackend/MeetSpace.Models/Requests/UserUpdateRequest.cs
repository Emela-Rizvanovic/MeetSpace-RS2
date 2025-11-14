using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class UserUpdateRequest
    {
        public int? RoleId { get; set; }

        public string? UserName { get; set; } = string.Empty;
        public string? FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; } = string.Empty;
        public string? Email { get; set; } = string.Empty;

        public string? PhoneNumber { get; set; }
        public string? ProfileImageUrl { get; set; }

        public bool? IsActive { get; set; } = true;
    }
}
