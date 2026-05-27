using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class AmenityCategoryInsertRequest
    {
        [Required(ErrorMessage = "Amenity category name is required.")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Amenity category name must contain 2-100 characters.")]
        public string Name { get; set; } = string.Empty;
    }
}