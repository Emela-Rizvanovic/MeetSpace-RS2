using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class BookingAmenityInsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Amenity is required. Select a valid amenity.")]
        public int AmenityId { get; set; }

        [Range(1, 100000, ErrorMessage = "Amenity quantity must be a whole number greater than 0.")]
        public int Quantity { get; set; }
    }
}