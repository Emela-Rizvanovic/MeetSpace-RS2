using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class ReviewUpdateRequest
    {
        [Range(1, 5, ErrorMessage = "Rating must be a whole number from 1 to 5.")]
        public int Rating { get; set; }

        [StringLength(1000, ErrorMessage = "Comment can contain up to 1000 characters.")]
        public string? Comment { get; set; }
    }
}