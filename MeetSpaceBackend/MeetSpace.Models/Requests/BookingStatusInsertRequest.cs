using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class BookingStatusInsertRequest
    {
        [Required, MaxLength(50)]
        public string Name { get; set; } = string.Empty;
    }
}
