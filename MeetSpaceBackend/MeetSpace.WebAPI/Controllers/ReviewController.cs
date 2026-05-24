using MeetSpace.Models.Constants;
using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.Interfaces;
using MeetSpace.WebAPI.BaseControllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

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

        // 🔹 Dodatni endpoint – Reviews za određeni prostor
        [AllowAnonymous]
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

        [AllowAnonymous]
        [HttpGet("space/{spaceId}/summary")]
        public async Task<ActionResult<ReviewSummaryResponse>> GetSummary(int spaceId)
        {
            var average = await _reviewService.GetAverageRatingAsync(spaceId);
            var count = await _reviewService.GetReviewCountAsync(spaceId);

            return Ok(new ReviewSummaryResponse
            {
                AverageRating = Math.Round(average, 2),
                TotalReviews = count
            });
        }

    }
}