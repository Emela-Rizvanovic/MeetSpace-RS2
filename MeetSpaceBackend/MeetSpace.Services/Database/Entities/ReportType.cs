namespace MeetSpace.Models.Entities
{
    public class ReportType
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public ICollection<Report> Reports { get; set; } = new HashSet<Report>();
    }
}
