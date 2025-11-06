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
    public class AmenityController : BaseCRUDController<AmenityResponse, AmenitySearchObject, AmenityInsertRequest, AmenityUpdateRequest>
    {
        private readonly IAmenityService _amenityService;

        public AmenityController(IAmenityService service) : base(service)
        {
            _amenityService = service;
        }
    }
}
