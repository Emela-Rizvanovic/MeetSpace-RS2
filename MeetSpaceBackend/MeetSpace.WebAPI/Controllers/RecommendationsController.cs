using MeetSpace.Models.Entities;
using MeetSpace.Services.Database;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MeetSpace.WebAPI.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class RecommendationsController : ControllerBase
    {
        private readonly IRecommendationService _service;
        private readonly MeetSpaceDbContext _context;

        public RecommendationsController(IRecommendationService service, MeetSpaceDbContext context)
        {
            _service = service;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized();

            var userId = int.Parse(userIdClaim);
            var spaces = await _service.GetRecommendedSpaces(userId);
            return Ok(spaces);

        }

        [HttpPost("{spaceId}/click")]
        public async Task<IActionResult> MarkClicked(int spaceId)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized();

            var userId = int.Parse(userIdClaim);

            var log = await _context.RecommendationLogs
                .Where(r => r.UserId == userId && r.SpaceId == spaceId)
                .OrderByDescending(r => r.RecommendedAt)
                .FirstOrDefaultAsync();

            if (log != null)
            {
                log.Clicked = true;
                await _context.SaveChangesAsync();
            }

            return Ok();
        }
    }
}
