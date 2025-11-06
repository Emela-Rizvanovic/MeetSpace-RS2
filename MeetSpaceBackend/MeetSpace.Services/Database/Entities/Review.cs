namespace MeetSpace.Models.Entities
{
    public class Review
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int SpaceId { get; set; }
        public int Rating { get; set; } // 1-5
        public string? Comment { get; set; }

        public User? User { get; set; }
        public Space? Space { get; set; }
        // Audit
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
