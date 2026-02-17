using Microsoft.AspNetCore.Http;
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

        // Dodavanje novih slika
        public List<IFormFile>? NewImages { get; set; }

        // Brisanje postojećih slika po ID-u
        public List<int>? DeleteImageIds { get; set; }

        public List<int>? AmenityIds { get; set; }

    }
}
