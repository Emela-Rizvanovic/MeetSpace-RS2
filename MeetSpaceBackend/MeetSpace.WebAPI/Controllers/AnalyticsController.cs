using MeetSpace.Models.Constants;
using MeetSpace.Models.Responses;
using MeetSpace.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class AnalyticsController : ControllerBase
    {
        private readonly IAnalyticsService _analyticsService;

        public AnalyticsController(IAnalyticsService analyticsService)
        {
            _analyticsService = analyticsService;
        }

        [HttpGet("spaces")]
        [Authorize(Roles = Roles.Admin)]
        [ProducesResponseType(typeof(IReadOnlyList<SpaceDemandResponse>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IReadOnlyList<SpaceDemandResponse>>> GetSpaceDemand(
            [FromQuery] string? cityCode,
            [FromQuery] string? facilityCode,
            [FromQuery] string? spaceTypeCode,
            [FromQuery] string? spaceCode,
            [FromQuery] DateTime? fromDate,
            [FromQuery] DateTime? toDate,
            CancellationToken cancellationToken)
        {
            if (fromDate.HasValue && toDate.HasValue && fromDate.Value.Date > toDate.Value.Date)
            {
                return BadRequest(new { message = "fromDate must be on or before toDate." });
            }

            var result = await _analyticsService.GetSpaceDemandAsync(
                cityCode,
                facilityCode,
                spaceTypeCode,
                spaceCode,
                fromDate,
                toDate,
                cancellationToken);

            return Ok(result);
        }

        [HttpGet("mobile-spaces")]
        [ProducesResponseType(typeof(IReadOnlyList<SpaceDemandResponse>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IReadOnlyList<SpaceDemandResponse>>> GetMobileSpaces(
            CancellationToken cancellationToken)
        {
            var result = await _analyticsService.GetSpaceDemandAsync(
                null, null, null, null, null, null, cancellationToken);
            return Ok(result);
        }

        [HttpGet("space-periods")]
        [ProducesResponseType(typeof(IReadOnlyList<SpaceDemandPeriodResponse>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IReadOnlyList<SpaceDemandPeriodResponse>>> GetSpaceDemandPeriods(
            [FromQuery] string spaceCode,
            [FromQuery] DateTime? fromDate,
            [FromQuery] DateTime? toDate,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(spaceCode))
            {
                return BadRequest(new { message = "spaceCode is required." });
            }

            if (fromDate.HasValue && toDate.HasValue && fromDate.Value.Date > toDate.Value.Date)
            {
                return BadRequest(new { message = "fromDate must be on or before toDate." });
            }

            var result = await _analyticsService.GetSpaceDemandPeriodsAsync(
                spaceCode, fromDate, toDate, cancellationToken);
            return Ok(result);
        }
    }
}
