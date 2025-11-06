namespace MeetSpace.Models.Entities
{
    public class AmenityCategory
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public ICollection<Amenity> Amenities { get; set; } = new HashSet<Amenity>();
    }
}
