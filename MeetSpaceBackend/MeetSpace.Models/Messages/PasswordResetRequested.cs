namespace MeetSpace.Models.Messages
{
    public class PasswordResetRequested
    {
        public int UserId { get; set; }
        public string UserName { get; set; }
        public string UserEmail { get; set; }
        public string ResetCode { get; set; }
        public DateTime RequestedAt { get; set; }
        public DateTime ExpiresAt { get; set; }
    }
}
