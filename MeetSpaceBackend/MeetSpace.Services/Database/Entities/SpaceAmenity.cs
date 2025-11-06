namespace MeetSpace.Models.Entities
{
    public class SpaceAmenity
    {
        public int SpaceId { get; set; }
        public int AmenityId { get; set; }

        public Space? Space { get; set; }
        public Amenity? Amenity { get; set; }
    }
}
