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
    public class BookingController : BaseCRUDController<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
    {
        private readonly IBookingService _bookingService;

        public BookingController(IBookingService service) : base(service)
        {
            _bookingService = service;
        }

        [HttpGet("user/{userId}")]
        public async Task<ActionResult<List<BookingResponse>>> GetByUser(int userId, CancellationToken ct)
        {
            var result = await _bookingService.GetByUserIdAsync(userId, ct);
            return Ok(result);
        }
    }
}
