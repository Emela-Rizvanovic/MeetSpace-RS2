using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Models.Requests
{
    public class SpaceUpdateRequest
    {
        public string? Name { get; set; } = string.Empty;
        public string? Description { get; set; } = string.Empty;
        public decimal? PricePerHour { get; set; }
        public int? Capacity { get; set; }
        public int? FacilityId { get; set; }
        public int? SpaceTypeId { get; set; }

        // UpdatedAt NE unosi user, to će servis automatski postaviti.

        // TO-DO
        // azurirati po potrebi vezano za slike i amenities nakon sto se i insert azurira
    }
}
