using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class CityUpdateRequest
    {
        [StringLength(100, MinimumLength = 2, ErrorMessage = "City name must contain 2-100 characters.")]
        public string? Name { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Country must be a valid selected country.")]
        public int? CountryId { get; set; }
    }
}