namespace MeetSpace.Models.SearchObjects
{
    public class SpaceSearchObject : BaseSearchObject
    {
        public bool? IsActive { get; set; }
        public string? Name { get; set; }
        public int? FacilityId { get; set; }
        public int? SpaceTypeId { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public int? MinCapacity { get; set; }
        public int? MaxCapacity { get; set; }
    }
}
