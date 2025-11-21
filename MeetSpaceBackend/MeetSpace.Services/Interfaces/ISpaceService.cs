using MeetSpace.Models.Requests;
using MeetSpace.Models.Responses;
using MeetSpace.Models.SearchObjects;
using MeetSpace.Services.BaseInterfaces;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Interfaces
{
    public interface ISpaceService : ICRUDService<SpaceResponse, SpaceSearchObject, SpaceInsertRequest, SpaceUpdateRequest>
    {
        Task<List<SpaceImageResponse>> AddImagesAsync(int spaceId, List<IFormFile> files);
    }
}
