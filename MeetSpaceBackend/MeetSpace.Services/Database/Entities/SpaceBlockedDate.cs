namespace MeetSpace.Models.Entities
{
    public class SpaceBlockedDate
    {
        public int Id { get; set; }
        public int SpaceId { get; set; }
        public DateTime Date { get; set; }
        public string? Reason { get; set; }

        public Space? Space { get; set; }
    }
}
