namespace MeetSpace.Models.Entities
{
    public class Favorite
    {
        public int UserId { get; set; }
        public int SpaceId { get; set; }

        public User? User { get; set; }
        public Space? Space { get; set; }
    }
}
