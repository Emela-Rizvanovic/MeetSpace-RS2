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
    public class ReportTypeController : BaseCRUDController<ReportTypeResponse, ReportTypeSearchObject, ReportTypeInsertRequest, ReportTypeUpdateRequest>
    {
        private readonly IReportTypeService _reportTypeService;

        public ReportTypeController(IReportTypeService service) : base(service)
        {
            _reportTypeService = service;
        }
    }
}
