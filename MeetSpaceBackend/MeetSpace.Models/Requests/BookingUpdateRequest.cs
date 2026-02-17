using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class BookingUpdateRequest
    {
        public int? SpaceId { get; set; }
        public int? UserId { get; set; }
        public int? BookingStatusId { get; set; }

        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }

        //public decimal? TotalPrice { get; set; }
    }
}
