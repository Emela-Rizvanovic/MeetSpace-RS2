using MeetSpace.Models.Constants;
using MeetSpace.Models.Requests;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using MeetSpace.Models.Exceptions;

[ApiController]
[Authorize]
[Route("api/[controller]")]
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
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        var roleClaim = User.FindFirst(ClaimTypes.Role);

        if (userIdClaim == null || roleClaim == null)
            throw new UnauthorizedAccessException("Unauthorized.");

        int currentUserId = int.Parse(userIdClaim.Value);
        string currentRole = roleClaim.Value;

        if (currentRole != Roles.Admin)
        {
            request.UserId = currentUserId;
        }
        else if (!request.UserId.HasValue || request.UserId.Value <= 0)
        {
            throw new BusinessException("User is required when administrator adds a favorite.");
        }

        await _service.AddAsync(request);
        return Ok();
    }

    [HttpDelete]
    public async Task<IActionResult> Remove(int userId, int spaceId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        var roleClaim = User.FindFirst(ClaimTypes.Role);

        if (userIdClaim == null || roleClaim == null)
            throw new UnauthorizedAccessException("Unauthorized.");

        int currentUserId = int.Parse(userIdClaim.Value);
        string currentRole = roleClaim.Value;

        if (currentRole != Roles.Admin && currentUserId != userId)
            throw new UnauthorizedAccessException("You cannot remove another user's favorite.");

        await _service.RemoveAsync(userId, spaceId);
        return Ok();
    }

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUser(int userId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        var roleClaim = User.FindFirst(ClaimTypes.Role);

        if (userIdClaim == null || roleClaim == null)
            throw new UnauthorizedAccessException("Unauthorized.");

        int currentUserId = int.Parse(userIdClaim.Value);
        string currentRole = roleClaim.Value;

        if (currentRole != Roles.Admin && currentUserId != userId)
            throw new UnauthorizedAccessException("You cannot access another user's favorites.");

        var result = await _service.GetByUserAsync(userId);
        return Ok(result);
    }
}