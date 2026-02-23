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
    [Authorize(Roles = "Admin")]
    [Route("api/[controller]")]
    public class BookingStatusController
        : BaseCRUDController<BookingStatusResponse, BookingStatusSearchObject, BookingStatusInsertRequest, BookingStatusUpdateRequest>
    {
        public BookingStatusController(IBookingStatusService service)
            : base(service)
        {
        }
    }
}
