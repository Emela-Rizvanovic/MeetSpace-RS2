using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class FacilityUpdateRequest
    {
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Facility name must contain 2-100 characters.")]
        public string? Name { get; set; }

        [StringLength(200, MinimumLength = 5, ErrorMessage = "Address must contain 5-200 characters.")]
        public string? Address { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "City must be a valid selected city.")]
        public int? CityId { get; set; }

        [StringLength(1000, ErrorMessage = "Description can contain up to 1000 characters.")]
        public string? Description { get; set; }

        [EmailAddress(ErrorMessage = "Contact email must be in a valid format, e.g. example@mail.com.")]
        public string? ContactEmail { get; set; }

        [RegularExpression(@"^\+?[0-9 ]{8,15}$", ErrorMessage = "Contact phone must contain 8-15 digits, optionally starting with +. Example: +387 61 123 456.")]
        public string? ContactPhone { get; set; }
    }
}