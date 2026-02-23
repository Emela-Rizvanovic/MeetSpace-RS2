using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class ReviewInsertRequest
    {
        public int UserId { get; set; }
        public int SpaceId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}
