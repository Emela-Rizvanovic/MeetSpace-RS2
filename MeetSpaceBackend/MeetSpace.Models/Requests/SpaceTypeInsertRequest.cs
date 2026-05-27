using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class SpaceTypeInsertRequest
    {
        [Required(ErrorMessage = "Space type name is required.")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Space type name must contain 2-100 characters.")]
        public string Name { get; set; } = string.Empty;
    }
}