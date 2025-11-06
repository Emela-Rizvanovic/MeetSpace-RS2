namespace MeetSpace.Models.Entities
{
    public class SpaceWorkingHours
    {
        public int Id { get; set; }
        public int SpaceId { get; set; }
        public DayOfWeek Day { get; set; }
        public TimeSpan OpenTime { get; set; }
        public TimeSpan CloseTime { get; set; }

        public Space? Space { get; set; }
    }
}
