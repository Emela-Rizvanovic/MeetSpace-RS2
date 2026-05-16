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
    [Authorize(Roles = Roles.Admin)]
    [Route("api/[controller]")]
    public class SpaceTypeController : BaseCRUDController<SpaceTypeResponse, SpaceTypeSearchObject, SpaceTypeInsertRequest, SpaceTypeUpdateRequest>
    {
        private readonly ISpaceTypeService _spaceTypeService;

        public SpaceTypeController(ISpaceTypeService service) : base(service)
        {
            _spaceTypeService = service;
        }
    }
}
