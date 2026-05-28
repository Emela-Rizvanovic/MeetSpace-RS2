using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Messages
{
    public class BookingStatusChangedMessage
    {
        public int UserId { get; set; } 
        public string SpaceName { get; set; }
        public DateTime StartTime { get; set; }
        public bool IsApproved { get; set; }
        public string? Reason { get; set; }
        public bool IsCancellation { get; set; }
    }
}
