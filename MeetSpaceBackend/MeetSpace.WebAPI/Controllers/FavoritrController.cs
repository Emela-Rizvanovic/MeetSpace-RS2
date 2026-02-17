using MeetSpace.Models.Requests;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace MeetSpace.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FavoriteController : ControllerBase
    {
        private readonly IFavoriteService _service;

        public FavoriteController(IFavoriteService service)
        {
            _service = service;
        }

        [HttpPost]
        public async Task<IActionResult> Add(FavoriteInsertRequest request)
        {
            await _service.AddAsync(request);
            return Ok();
        }

        [HttpDelete]
        public async Task<IActionResult> Remove(int userId, int spaceId)
        {
            await _service.RemoveAsync(userId, spaceId);
            return Ok();
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUser(int userId)
        {
            var result = await _service.GetByUserAsync(userId);
            return Ok(result);
        }
    }

}
