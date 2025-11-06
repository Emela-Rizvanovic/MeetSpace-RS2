namespace MeetSpace.Models.Entities
{
    public class SpaceImage
    {
        public int Id { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public int SpaceId { get; set; }

        public Space? Space { get; set; }
    }
}
