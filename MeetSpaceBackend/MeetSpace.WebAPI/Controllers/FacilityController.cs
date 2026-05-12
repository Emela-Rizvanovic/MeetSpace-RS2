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
    public class FacilityController
    : BaseCRUDController<FacilityResponse, FacilitySearchObject, FacilityInsertRequest, FacilityUpdateRequest>
    {
        private readonly IFacilityService _facilityService;

        public FacilityController(IFacilityService service) : base(service)
        {
            _facilityService = service;
        }

        [AllowAnonymous]
        [HttpGet]
        public override Task<PagedResult<FacilityResponse>> Get([FromQuery] FacilitySearchObject search)
        {
            return base.Get(search);
        }

        [AllowAnonymous]
        [HttpGet("{id}")]
        public override Task<FacilityResponse?> GetById(int id)
        {
            return base.GetById(id);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost]
        public override Task<FacilityResponse> Create(FacilityInsertRequest request)
        {
            return base.Create(request);
        }

        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public override Task<FacilityResponse?> Update(int id, FacilityUpdateRequest request)
        {
            return base.Update(id, request);
        }

        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public override Task<bool> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}
