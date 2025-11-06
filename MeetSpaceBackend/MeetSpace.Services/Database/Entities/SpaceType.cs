namespace MeetSpace.Models.Entities
{
    public class SpaceType
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public ICollection<Space> Spaces { get; set; } = new HashSet<Space>();
    }
}
