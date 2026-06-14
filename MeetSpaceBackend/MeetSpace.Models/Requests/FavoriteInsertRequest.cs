using System.ComponentModel.DataAnnotations;

namespace MeetSpace.Models.Requests
{
    public class FavoriteInsertRequest
    {
        public int? UserId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Space is required. Select a valid space.")]
        public int SpaceId { get; set; }
    }
}