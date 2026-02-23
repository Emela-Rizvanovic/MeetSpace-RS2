using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? SpaceId { get; set; }
        public int? UserId { get; set; }

        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }

        public DateTime? CreatedFrom { get; set; }
        public DateTime? CreatedTo { get; set; }

        public bool? SortByNewest { get; set; }
    }
}
