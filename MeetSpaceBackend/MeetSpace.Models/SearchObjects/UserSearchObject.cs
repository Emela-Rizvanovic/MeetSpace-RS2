namespace MeetSpace.Models.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? RoleId { get; set; }
        public bool? IsActive { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
    }
}
