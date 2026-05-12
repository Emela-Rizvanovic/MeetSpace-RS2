namespace MeetSpace.Models.Responses
{
    public class CityResponse
    {
        public int Id { get; set; }

        public string Name { get; set; }

        public int CountryId { get; set; }

        public string CountryName { get; set; }
    }
}