using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class CountryInsertRequest
    {
        [Required(ErrorMessage = "Country name is required.")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Country name must contain 2-100 characters.")]
        public string Name { get; set; } = string.Empty;
    }
}