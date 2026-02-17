using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.SearchObjects
{
    public class BookingSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? SpaceId { get; set; }
        public int? BookingStatusId { get; set; }

        public DateTime? StartFrom { get; set; }
        public DateTime? StartTo { get; set; }
    }
}
