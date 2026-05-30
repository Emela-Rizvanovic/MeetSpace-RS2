using MeetSpace.Models.Constants;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.Interfaces;
using MeetSpace.WebAPI.BaseControllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MeetSpace.WebAPI.Controllers
{
    [ApiController]
    [Authorize(Roles = Roles.Admin)]
    [Route("api/[controller]")]
    public class RevenueController
        : BaseController<RevenueResponse, RevenueSearchObject>
    {
        private readonly IRevenueService _service;

        public RevenueController(IRevenueService service)
            : base(service)
        {
            _service = service;
        }

        [HttpGet]
        public override Task<PagedResult<RevenueResponse>> Get([FromQuery] RevenueSearchObject search)
        {
            return base.Get(search);
        }

        [HttpGet("latest")]
        public async Task<IActionResult> GetLatest()
        {
            var data = await _service.GetLatest();
            return Ok(data);
        }

        [HttpGet("total")]
        public async Task<IActionResult> GetTotal()
        {
            var total = await _service.GetTotal();
            return Ok(total);
        }
    }
}