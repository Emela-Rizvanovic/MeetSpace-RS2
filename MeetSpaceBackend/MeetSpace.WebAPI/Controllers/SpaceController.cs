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
    public class SpaceController : BaseCRUDController<SpaceResponse, SpaceSearchObject, SpaceInsertRequest, SpaceUpdateRequest>
    {
        private readonly ISpaceService _spaceService;

        public SpaceController(ISpaceService service) : base(service)
        {
            _spaceService = service;
        }

        [HttpPost]
        [Consumes("multipart/form-data")]
        public override Task<SpaceResponse> Create([FromForm] SpaceInsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("{id}")]
        [Consumes("multipart/form-data")]
        public override Task<SpaceResponse?> Update(int id, [FromForm] SpaceUpdateRequest request)
        {
            return base.Update(id, request);
        }

        [HttpPost("{id}/images")]
        public async Task<IActionResult> AddImages(int id, [FromForm] List<IFormFile> images)
        {
            var result = await _spaceService.AddImagesAsync(id, images);
            return Ok(result);
        }


        // Minimalni CRUD koristi BaseCRUDController
        // Za sada nema dodatnih custom metoda
        // Kada bude potrebno, možemo dodati npr. pretragu po datumu, kapacitetu, tipovima prostora, upload slika itd.

        // TO-DO 
        // azurirati ga kao i sve kad dodje vrijeme
    }
}
