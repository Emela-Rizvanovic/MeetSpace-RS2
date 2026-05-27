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
    public class AmenityController
    : BaseCRUDController<AmenityResponse, AmenitySearchObject, AmenityInsertRequest, AmenityUpdateRequest>
    {
        private readonly IAmenityService _amenityService;

        public AmenityController(IAmenityService service) : base(service)
        {
            _amenityService = service;
        }

        [HttpGet]
        public override Task<PagedResult<AmenityResponse>> Get([FromQuery] AmenitySearchObject search)
        {
            return base.Get(search);
        }

        [HttpGet("{id}")]
        public override Task<AmenityResponse?> GetById(int id)
        {
            return base.GetById(id);
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpPost]
        public override Task<AmenityResponse> Create(AmenityInsertRequest request)
        {
            return base.Create(request);
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpPut("{id}")]
        public override Task<AmenityResponse?> Update(int id, AmenityUpdateRequest request)
        {
            return base.Update(id, request);
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override Task<bool> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}
