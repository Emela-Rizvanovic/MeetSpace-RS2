using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class RoleInsertRequest
    {
        [Required(ErrorMessage = "Role name is required.")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Role name must contain 2-50 characters.")]
        public string Name { get; set; } = string.Empty;
    }
}