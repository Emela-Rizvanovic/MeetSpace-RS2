namespace MeetSpace.Models.Entities
{
    public class Report
    {
        public int Id { get; set; }
        public int ReportTypeId { get; set; }
        public string FilePath { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;

        public ReportType? ReportType { get; set; }
        // Audit
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
