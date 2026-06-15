using MeetSpace.Models.Constants;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.Interfaces;
using MeetSpace.WebAPI.BaseControllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeetSpace.Models.Exceptions;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class ReviewController
        : BaseCRUDController<
            ReviewResponse,
            ReviewSearchObject,
            ReviewInsertRequest,
            ReviewUpdateRequest>
    {
        private readonly IReviewService _reviewService;

        public ReviewController(IReviewService service) : base(service)
        {
            _reviewService = service;
        }


        [HttpPost]
        public override async Task<ReviewResponse> Create(ReviewInsertRequest request)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

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
                throw new BusinessException("User is required when administrator creates a review.");
            }

            return await base.Create(request);
        }

        [HttpPut("{id}")]
        public override async Task<ReviewResponse?> Update(int id, ReviewUpdateRequest request)
        {
            var review = await _reviewService.GetByIdAsync(id);

            if (review == null)
                return null;

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

            if (userIdClaim == null || roleClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);
            string currentRole = roleClaim.Value;

            if (currentRole != Roles.Admin && review.UserId != currentUserId)
                throw new UnauthorizedAccessException("You cannot modify this review.");

            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
        {
            var review = await _reviewService.GetByIdAsync(id);

            if (review == null)
                return false;

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

            if (userIdClaim == null || roleClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);
            string currentRole = roleClaim.Value;

            if (currentRole != Roles.Admin && review.UserId != currentUserId)
                throw new UnauthorizedAccessException("You cannot delete this review.");

            return await base.Delete(id);
        }

        [HttpGet("{id}")]
        public override async Task<ReviewResponse?> GetById(int id)
        {
            var review = await _reviewService.GetByIdAsync(id);

            if (review == null)
                return null;

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

            if (userIdClaim == null || roleClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);
            string currentRole = roleClaim.Value;

            if (currentRole != Roles.Admin && review.UserId != currentUserId)
                throw new UnauthorizedAccessException("You cannot access this review.");

            return review;
        }

        [HttpGet]
        public override async Task<PagedResult<ReviewResponse>> Get([FromQuery] ReviewSearchObject search)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

            if (userIdClaim == null || roleClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);
            string currentRole = roleClaim.Value;

            if (currentRole != Roles.Admin)
            {
                search.UserId = currentUserId;
            }

            return await base.Get(search);
        }

        
        [HttpGet("space/{spaceId}")]
        public async Task<ActionResult<List<ReviewResponse>>> GetBySpace(int spaceId, CancellationToken ct)
        {
            var search = new ReviewSearchObject
            {
                SpaceId = spaceId,
                SortByNewest = true
            };

            var result = await _reviewService.GetAsync(search);
            return Ok(result.Items);
        }

        [HttpGet("space/{spaceId}/summary")]
        public async Task<ActionResult<ReviewSummaryResponse>> GetSummary(int spaceId)
        {
            var summary = await _reviewService.GetSummaryAsync(spaceId);

            return Ok(summary);
        }

    }
}