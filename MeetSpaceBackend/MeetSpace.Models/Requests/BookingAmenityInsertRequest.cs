using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class BookingAmenityInsertRequest
    {
        public int AmenityId { get; set; }
        public int Quantity { get; set; }
    }
}
