using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class SpaceTypeUpdateRequest
    {
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Space type name must contain 2-100 characters.")]
        public string? Name { get; set; }
    }
}