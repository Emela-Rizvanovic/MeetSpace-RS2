using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.SearchObjects
{
    public class FacilitySearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? Address { get; set; }
        public int? CityId { get; set; }
        public int? CountryID { get; set; }
    }
}
