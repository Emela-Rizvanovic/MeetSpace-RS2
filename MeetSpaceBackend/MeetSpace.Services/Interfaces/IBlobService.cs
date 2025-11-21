using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MeetSpace.Services.Interfaces
{
    public interface IBlobService
    {
        Task<string> UploadUserImageAsync(IFormFile file);
        Task<string> UploadSpaceImageAsync(IFormFile file);

        Task<bool> DeleteUserImageAsync(string fileUrl);
        Task<bool> DeleteSpaceImageAsync(string fileUrl);
    }
}
