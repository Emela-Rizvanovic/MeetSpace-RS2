namespace MeetSpace.Models.Responses
{
    public class FacilityResponse
    {
        public int Id { get; set; }

        public string Name { get; set; } = null!;

        public string Address { get; set; } = null!;

        public int CityId { get; set; }

        public string CityName { get; set; } = null!;

        public string CountryName { get; set; } = null!;

        public string? Description { get; set; }

        public string? ContactEmail { get; set; }

        public string? ContactPhone { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime? UpdatedAt { get; set; }
    }
}
