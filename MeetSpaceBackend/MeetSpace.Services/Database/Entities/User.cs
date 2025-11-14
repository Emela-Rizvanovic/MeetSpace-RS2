using System.Data;

namespace MeetSpace.Models.Entities
{
    public class User
    {
         public int Id { get; set; }
         public int RoleId { get; set; }

         public string FirstName { get; set; }
         public string LastName { get; set; }
         public string Username { get; set; }
         public string Email { get; set; }
         public string PasswordHash { get; set; }
         public string? PhoneNumber { get; set; }
         public string? ProfileImageUrl { get; set; } 

        public bool IsActive { get; set; } = true;
         public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
         public DateTime? UpdatedAt { get; set; }

         // Navigation
         public virtual Role Role { get; set; }
         public virtual ICollection<Booking> Bookings { get; set; }
         public virtual ICollection<Review> Reviews { get; set; }
         public virtual ICollection<Favorite> Favorites { get; set; }
         public virtual ICollection<Notification> Notifications { get; set; }

         public User()
         {
             Bookings = new HashSet<Booking>();
             Reviews = new HashSet<Review>();
             Favorites = new HashSet<Favorite>();
             Notifications = new HashSet<Notification>();
         }
    }
}

