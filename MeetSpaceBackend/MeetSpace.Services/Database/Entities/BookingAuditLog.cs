using System;

namespace MeetSpace.Models.Entities
{
    public class BookingAuditLog
    {
        public int Id { get; set; }

        public int BookingId { get; set; }
        public Booking Booking { get; set; }

        public int AdminId { get; set; }
        public User Admin { get; set; }

        public string Action { get; set; } // Approved / Rejected

        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}