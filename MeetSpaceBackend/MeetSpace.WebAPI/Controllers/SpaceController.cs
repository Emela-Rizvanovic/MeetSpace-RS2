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
    public class SpaceController : BaseCRUDController<SpaceResponse, SpaceSearchObject, SpaceInsertRequest, SpaceUpdateRequest>
    {
        private readonly ISpaceService _spaceService;

        public SpaceController(ISpaceService service) : base(service)
        {
            _spaceService = service;
        }

        [HttpGet]
        public override Task<PagedResult<SpaceResponse>> Get([FromQuery] SpaceSearchObject search)
        {
            return base.Get(search);
        }

        [HttpGet("{id}")]
        public override Task<SpaceResponse?> GetById(int id)
        {
            return base.GetById(id);
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpPost]
        [Consumes("multipart/form-data")]
        public override Task<SpaceResponse> Create([FromForm] SpaceInsertRequest request)
        {
            return base.Create(request);
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpPut("{id}")]
        [Consumes("multipart/form-data")]
        public override Task<SpaceResponse?> Update(int id, [FromForm] SpaceUpdateRequest request)
        {
            return base.Update(id, request);
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpPost("{id}/images")]
        public async Task<IActionResult> AddImages(int id, [FromForm] List<IFormFile> images)
        {
            var result = await _spaceService.AddImagesAsync(id, images);
            return Ok(result);
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpDelete("{id}")]
        public override Task<bool> Delete(int id)
        {
            return base.Delete(id);
        }

    }
}
