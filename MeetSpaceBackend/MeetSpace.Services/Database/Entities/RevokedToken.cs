using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MeetSpace.Services.Database.Entities
{
    public class RevokedToken
    {
        [Key]
        public int Id { get; set; }

        [Required, Column("jti"), MaxLength(100)]
        public string Jti { get; set; } = string.Empty;

        [Required, Column("revoked_at")]
        public DateTime RevokedAt { get; set; } = DateTime.UtcNow;

        [Required, Column("expires_at")]
        public DateTime ExpiresAt { get; set; }
    }
}