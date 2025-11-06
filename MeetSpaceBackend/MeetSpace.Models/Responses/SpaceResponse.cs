using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Responses
{
    public class SpaceResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal PricePerHour { get; set; }
        public int Capacity { get; set; }
        public int FacilityId { get; set; }
        public int SpaceTypeId { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Kasnije možemo ubaciti naziv Facility / SpaceType → npr. FacilityName = string?
        // TO-DO isprovjeravati sve nakon azuriranja i dodataka
    }
}

