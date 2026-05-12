namespace MeetSpace.Models.SearchObjects
{
    public class CitySearchObject : BaseSearchObject
    {
        public string? Name { get; set; }

        public int? CountryId { get; set; }
    }
}