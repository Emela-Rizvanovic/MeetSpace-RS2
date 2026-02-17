using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class FavoriteInsertRequest
    {
        public int UserId { get; set; }
        public int SpaceId { get; set; }
    }
}
