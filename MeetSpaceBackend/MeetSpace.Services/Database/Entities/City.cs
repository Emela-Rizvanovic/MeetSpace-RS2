using System.Diagnostics.Metrics;

namespace MeetSpace.Models.Entities
{
    public class City
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int CountryId { get; set; }

        // Navigation
        public virtual Country Country { get; set; }
        public virtual ICollection<Facility> Facilities { get; set; }

        public City()
        {
            Facilities = new HashSet<Facility>();
        }
    }
}
