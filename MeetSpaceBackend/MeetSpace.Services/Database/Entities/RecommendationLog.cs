namespace MeetSpace.Models.Entities
{
    public class RecommendationLog
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int SpaceId { get; set; }
        public DateTime RecommendedAt { get; set; } = DateTime.UtcNow;
        public bool Clicked { get; set; } = false;
        public bool Booked { get; set; } = false;

        public User? User { get; set; }
        public Space? Space { get; set; }
    }
}
