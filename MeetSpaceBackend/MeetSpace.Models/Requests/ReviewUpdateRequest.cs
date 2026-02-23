using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class ReviewUpdateRequest
    {
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}
