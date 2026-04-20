using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Responses
{
    public class BookingResponse
    {
        public int Id { get; set; }
        public int SpaceId { get; set; }
        public int UserId { get; set; }
        public int BookingStatusId { get; set; }

        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal TotalPrice { get; set; }
        public string? Username { get; set; }
        public string? SpaceImageUrl { get; set; }
        public string? UserFullName { get; set; }
        public string? UserEmail { get; set; }
        public string? UserPhone { get; set; }
        public string? RejectionReason { get; set; }
        public string? PaymentStatusName { get; set; }

        public string? LastAction { get; set; }
        public string? LastAdminName { get; set; }
        public DateTime? LastActionAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Za prikaz u profilu (nije obavezno, ali korisno)
        public string? SpaceName { get; set; }
        public string? StatusName { get; set; }
        public string? FacilityAddress { get; set; }
    }
}

