namespace MeetSpace.Models.Entities
{
    public class Role
    {
        public int Id { get; set; }
        public string Name { get; set; } // e.g. "Admin", "User"

        public virtual ICollection<User> Users { get; set; }

        public Role()
        {
            Users = new HashSet<User>();
        }
    }
}
