using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class AmenityInsertRequest
    {
        [Required(ErrorMessage = "Amenity name is required.")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Amenity name must contain 2-100 characters.")]
        public string Name { get; set; } = string.Empty;

        [StringLength(500, ErrorMessage = "Description can contain up to 500 characters.")]
        public string? Description { get; set; }

        [Range(0, 100000, ErrorMessage = "Price must be a valid number greater than or equal to 0, e.g. 10.50.")]
        public decimal Price { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Amenity category is required. Select a valid category from the list.")]
        public int AmenityCategoryId { get; set; }
    }
}