using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.SearchObjects
{
    public class SpaceSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? FacilityId { get; set; }
        public int? SpaceTypeId { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public int? MinCapacity { get; set; }
        public int? MaxCapacity { get; set; }
    }
}
