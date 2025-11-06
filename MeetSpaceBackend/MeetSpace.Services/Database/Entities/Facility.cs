namespace MeetSpace.Models.Entities
{
    public class Facility
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Address { get; set; }
        public int CityId { get; set; }
        public string? Description { get; set; }
        public string? ContactEmail { get; set; }
        public string? ContactPhone { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        // Navigation
        public virtual City City { get; set; }
        public virtual ICollection<Space> Spaces { get; set; }

        public Facility()
        {
            Spaces = new HashSet<Space>();
        }
    }
}
