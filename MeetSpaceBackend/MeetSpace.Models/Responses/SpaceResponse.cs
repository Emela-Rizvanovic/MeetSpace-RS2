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
        public string? FacilityName { get; set; }
        public string? FacilityAddress { get; set; }

        public double AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public string? RecommendationReason { get; set; }

        public int SpaceTypeId { get; set; }
        public string? SpaceTypeName { get; set; }

        public List<SpaceImageResponse> Images { get; set; } = new();
        public List<AmenityResponse> Amenities { get; set; } = new();

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

    }
}

