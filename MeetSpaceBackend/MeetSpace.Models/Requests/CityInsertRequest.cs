using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class CityInsertRequest
    {
        [Required(ErrorMessage = "City name is required.")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "City name must contain 2-100 characters.")]
        public string Name { get; set; } = string.Empty;

        [Range(1, int.MaxValue, ErrorMessage = "Country is required. Select a valid country from the list.")]
        public int CountryId { get; set; }
    }
}