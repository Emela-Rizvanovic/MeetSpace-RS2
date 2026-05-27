using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class SpaceInsertRequest
    {
        [Required(ErrorMessage = "Space name is required.")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Space name must contain 2-100 characters.")]
        public string Name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Description is required.")]
        [StringLength(1000, MinimumLength = 10, ErrorMessage = "Description must contain 10-1000 characters.")]
        public string Description { get; set; } = string.Empty;

        [Range(0.01, 100000, ErrorMessage = "Price per hour must be a number greater than 0, e.g. 25.50.")]
        public decimal PricePerHour { get; set; }

        [Range(1, 100000, ErrorMessage = "Capacity must be a whole number greater than 0.")]
        public int Capacity { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Facility is required. Select a valid facility from the list.")]
        public int FacilityId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Space type is required. Select a valid space type from the list.")]
        public int SpaceTypeId { get; set; }

        public List<IFormFile>? Images { get; set; }

        public List<int>? AmenityIds { get; set; }
    }
}