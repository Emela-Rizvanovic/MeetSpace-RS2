using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseInterfaces;

namespace MeetSpace.Services.Interfaces
{
    public interface ICityService
        : ICRUDService<
            CityResponse,
            CitySearchObject,
            CityInsertRequest,
            CityUpdateRequest>
    {
    }
}