using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class FavoriteInsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "User is required. Select a valid user.")]
        public int UserId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Space is required. Select a valid space.")]
        public int SpaceId { get; set; }
    }
}