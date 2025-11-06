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
    public class SpaceTypeController : BaseCRUDController<SpaceTypeResponse, SpaceTypeSearchObject, SpaceTypeInsertRequest, SpaceTypeUpdateRequest>
    {
        private readonly ISpaceTypeService _spaceTypeService;

        public SpaceTypeController(ISpaceTypeService service) : base(service)
        {
            _spaceTypeService = service;
        }

        // Minimalni CRUD koristi BaseCRUDController
        // Za sada nema dodatnih custom metoda
        // Kada bude potrebno, možemo dodati npr. pretragu po datumu, kapacitetu, tipovima prostora, upload slika itd.

        // TO-DO 
        // azurirati ga kao i sve kad dodje vrijeme
    }
}
