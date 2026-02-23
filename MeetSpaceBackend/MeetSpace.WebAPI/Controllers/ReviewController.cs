using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.Interfaces;
using MeetSpace.WebAPI.BaseControllers;
using Microsoft.AspNetCore.Mvc;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
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

        // 🔹 Dodatni endpoint – Reviews za određeni prostor
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
        public async Task<ActionResult<object>> GetSummary(int spaceId)
        {
            var average = await _reviewService.GetAverageRatingAsync(spaceId);
            var count = await _reviewService.GetReviewCountAsync(spaceId);

            return Ok(new
            {
                averageRating = Math.Round(average, 2),
                totalReviews = count
            });
        }

    }
}