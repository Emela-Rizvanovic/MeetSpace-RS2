using MeetSpace.Models.Constants;
using MeetSpace.Models.Exceptions;
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
    public class BookingController : BaseCRUDController<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
    {
        private readonly IBookingService _bookingService;

        public BookingController(IBookingService service) : base(service)
        {
            _bookingService = service;
        }

        [HttpPost]
        public override async Task<BookingResponse> Create(BookingInsertRequest request)
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
        public override async Task<BookingResponse?> Update(int id, BookingUpdateRequest request)
        {
            var booking = await _bookingService.GetByIdAsync(id);

            if (booking == null)
                return null;

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

            if (userIdClaim == null || roleClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);
            string currentRole = roleClaim.Value;

            if (currentRole != Roles.Admin && booking.UserId != currentUserId)
                throw new UnauthorizedAccessException("You cannot modify this booking.");

            return await base.Update(id, request);
        }


        [HttpGet]
        public override async Task<PagedResult<BookingResponse>> Get([FromQuery] BookingSearchObject search)
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


        [HttpGet("{id}")]
        public override async Task<BookingResponse?> GetById(int id)
        {
            var booking = await _bookingService.GetByIdAsync(id);

            if (booking == null)
                return null;

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

            if (userIdClaim == null || roleClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);
            string currentRole = roleClaim.Value;

            if (currentRole != Roles.Admin && booking.UserId != currentUserId)
                throw new UnauthorizedAccessException("You cannot access this booking.");

            return booking;
        }

        [HttpGet("user/{userId}")]
        public async Task<ActionResult<List<BookingResponse>>> GetByUser(int userId, CancellationToken ct)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role);

            if (userIdClaim == null || roleClaim == null)
                throw new UnauthorizedAccessException("Unauthorized.");

            int currentUserId = int.Parse(userIdClaim.Value);
            string currentRole = roleClaim.Value;

            if (currentRole != Roles.Admin && currentUserId != userId)
                throw new UnauthorizedAccessException("You cannot access other users' bookings.");

            var result = await _bookingService.GetByUserIdAsync(userId, ct);
            return Ok(result);
        }

        [HttpGet("space/{spaceId}")]
        public async Task<ActionResult<List<BookingResponse>>> GetBySpace(int spaceId, CancellationToken ct)
        {
            var result = await _bookingService.GetBySpaceIdAsync(spaceId, ct);
            return Ok(result);
        }

        [HttpPut("{id}/approve")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Approve(int id)
        {
            var booking = await _bookingService.GetByIdAsync(id);

            if (booking == null)
                return NotFound();

            await _bookingService.ApproveAsync(id);

            return Ok();
        }

        [HttpPut("{id}/reject")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Reject(int id, [FromBody] RejectRequest reason)
        {
            var booking = await _bookingService.GetByIdAsync(id);

            if (booking == null)
                return NotFound();

            await _bookingService.RejectAsync(id, reason.Reason);

            return Ok();
        }

        [HttpPut("{id}/cancel")]
        public async Task<IActionResult> Cancel(int id, [FromBody] RejectRequest reason)
        {
            var booking = await _bookingService.GetByIdAsync(id);

            if (booking == null)
                return NotFound();

            await _bookingService.CancelAsync(id, reason.Reason);

            return Ok();
        }

        [HttpGet("check-conflict")]
        public async Task<IActionResult> CheckConflict(int spaceId, DateTime start, DateTime end, int? ignoreId)
        {
            var result = await _bookingService.HasConflict(spaceId, start, end, ignoreId);
            return Ok(new BookingConflictResponse
            {
                HasConflict = result
            });
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpPost("{id}/send-reminder")]
        public async Task<IActionResult> SendReminder(int id)
        {
            await _bookingService.SendReminderAsync(id);

            return Ok();
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = Roles.Admin)]
        public override Task<bool> Delete(int id)
        {
            throw new BusinessException(
                "Bookings cannot be deleted because they are kept as booking history."
            );
        }


    }
}
