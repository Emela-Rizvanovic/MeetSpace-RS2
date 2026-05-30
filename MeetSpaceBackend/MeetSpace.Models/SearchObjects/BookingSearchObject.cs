namespace MeetSpace.Models.SearchObjects
{
    public class BookingSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? SpaceId { get; set; }
        public int? BookingStatusId { get; set; }
        public string? Name { get; set; }
        public bool? IsUpcoming { get; set; }

        public DateTime? StartFrom { get; set; }
        public DateTime? StartTo { get; set; }
    }
}
